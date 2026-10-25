import SwiftUI
import UIKit

struct ChatView: View {
    @StateObject private var model: ChatViewModel
    @EnvironmentObject private var router: AppRouter
    @FocusState private var isInputFocused: Bool
    @State private var isConfirmingDelete = false
    
    init(chatId: UUID?, dependencies: AppDependencies) {
        _model = StateObject(wrappedValue: ChatViewModel(
            chatId: chatId,
            repository: dependencies.chats,
            service: dependencies.chat,
            subscription: dependencies.subscription,
            copyToPasteboard: { text in
                UIPasteboard.general.string = text
                return UIPasteboard.general.string == text
            }
        ))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            AvatarHeader(
                icon: "IconSparkles",
                title: "AI Chat",
                subtitle: model.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year()),
                isPinned: model.isPinned,
                onBack: { router.pop() }
            ) {
                if model.hasMenu {
                    chatMenu
                }
            }
            Group {
                if model.isEmpty {
                    emptyState
                } else {
                    messageList
                }
            }
            .frame(maxHeight: .infinity)
            MessageInputBar(
                text: $model.draft,
                placeholder: "How can I help you?",
                isSendEnabled: model.canSend,
                focus: $isInputFocused
            ) {
                Haptics.play(.tap)
                Task { await model.send() }
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toast($model.toast)
        .haptic(on: model.toast, ToastMessage.haptic(for:))
        .alert("Delete chat?", isPresented: $isConfirmingDelete) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    if await model.deleteChat() { router.popToRoot() }
                }
            }
        } message: {
            Text("This chat will be removed from your history.")
        }
        .task(id: model.chatId) { await model.observe() }
        .onAppear {
            model.onPaywall = { [router] in router.showPaywall(from: .premiumAction) }
            guard model.chatId == nil else { return }
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                isInputFocused = true
            }
        }
    }
    
    private var chatMenu: some View {
        Menu {
            ShareLink(item: model.shareText) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                Task { await model.togglePin() }
            } label: {
                if model.isPinned {
                    Label("Unpin chat", systemImage: "pin.slash")
                } else {
                    Label("Pin chat", systemImage: "pin")
                }
            }
            Button(role: .destructive) {
                isConfirmingDelete = true
            } label: {
                Label("Delete chat", systemImage: "trash")
            }
        } label: {
            Image("ButtonMore")
                .frame(width: 40, height: 40)
                .contentShape(Circle())
        }
        .accessibilityLabel(Text("Chat actions"))
    }
    
    private var emptyState: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text(Self.greeting)
                    .font(AppFont.title3)
                    .foregroundStyle(Color.appAccent)
                Text("Pick a suggestion below or ask your own question")
                    .font(AppFont.subheadline)
                    .foregroundStyle(Color.appAccent.opacity(0.5))
            }
            .multilineTextAlignment(.center)
            FlowLayout(spacing: 8) {
                ForEach(ChatViewModel.suggestions, id: \.key) { suggestion in
                    ChipButton(title: String(localized: suggestion), style: .suggestion) {
                        model.useSuggestion(suggestion)
                        isInputFocused = true
                    }
                }
            }
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { isInputFocused = false }
    }
    
    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 24) {
                    ForEach(model.messages) { message in
                        row(message)
                            .id(message.id)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, AppMetrics.sideInset)
                .padding(.vertical, 24)
                .animation(.easeOut(duration: 0.3), value: model.messages)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollToBottom(proxy, animated: false) }
            .onChange(of: model.messages.last) { _ in scrollToBottom(proxy, animated: true) }
            .onChange(of: isInputFocused) { focused in
                if focused { scrollToBottom(proxy, animated: true) }
            }
        }
    }
    
    @ViewBuilder
    private func row(_ message: Message) -> some View {
        switch message.role {
            case .user:
                UserBubble(message: message)
            case .assistant:
                AssistantBubble(
                    message: message,
                    canRegenerate: model.canRegenerate(message),
                    onCopy: { model.copy(message) },
                    onRetry: { Task { await model.retry(message) } }
                )
        }
    }
    
    private static var greeting: AttributedString {
        var text = AttributedString(localized: "Your **AI assistant** for anything")
        for run in text.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            text[run.range].foregroundColor = .appGradientStart
            text[run.range].inlinePresentationIntent = nil
        }
        return text
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy, animated: Bool) {
        guard let last = model.messages.last else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.3)) { proxy.scrollTo(last.id, anchor: .bottom) }
        } else {
            proxy.scrollTo(last.id, anchor: .bottom)
        }
    }
}

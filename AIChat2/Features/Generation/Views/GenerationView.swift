import PhotosUI
import SwiftUI
import UIKit

struct GenerationView: View {
    @StateObject private var model: GenerationViewModel
    @EnvironmentObject private var router: AppRouter
    @State private var isPickerPresented = false
    @State private var pickerItem: PhotosPickerItem?
    private let photoAccess: any PhotoLibraryAccess
    
    init(id: UUID, dependencies: AppDependencies) {
        photoAccess = dependencies.photoAccess
        let video = dependencies.video
        _model = StateObject(wrappedValue: GenerationViewModel(
            id: id,
            repository: dependencies.videos,
            media: dependencies.media,
            photoSaver: dependencies.photoSaver,
            service: video
        ) { generation, photo in
            let template = VideoTemplate(
                id: generation.templateId,
                name: generation.templateName,
                category: "",
                previewURL: nil,
                qualities: [],
                duration: nil
            )
            return try await video.create(template: template, photo: photo, aspect: generation.aspect, quality: generation.quality)
        })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            NavigationHeader(model.isResult ? "Result" : nil) { router.pop() }
            content
                .frame(maxHeight: .infinity)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: model.phase)
        .toast($model.toast)
        .haptic(on: model.toast, ToastMessage.haptic(for:))
        .haptic(on: model.saveResult) { result in
            switch result {
                case .saved: .success
                case .failed: .error
                case nil: nil
            }
        }
        .haptic(on: model.isResult) { $0 ? .success : nil }
        .task { await model.observe() }
        .onAppear {
            model.onReplaced = { [router] id in router.replaceTop(with: .generation(id: id)) }
        }
        .photosPicker(isPresented: $isPickerPresented, selection: $pickerItem, matching: .images)
        .onChange(of: pickerItem) { item in
            guard let item else { return }
            pickerItem = nil
            Task {
                guard let data = try? await item.loadTransferable(type: Data.self) else {
                    model.toast = ToastMessage(kind: .failure, text: "Upload failed")
                    return
                }
                await model.replacePhoto(data)
            }
        }
        .sheet(isPresented: Binding(get: { model.shareURL != nil }, set: { if !$0 { model.shareURL = nil } })) {
            if let url = model.shareURL {
                ShareSheet(items: [url])
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch model.phase {
            case .loading:
                Color.clear
            case .generating:
                GeneratingView()
                    .transition(.opacity)
            case let .ready(url):
                result(url)
                    .transition(.opacity)
            case let .failed(kind):
                LoadErrorView(kind: kind) { Task { await model.retry() } }
            case .missing:
                LoadErrorView(kind: .notFound) { router.pop() }
        }
    }
    
    private func result(_ url: URL) -> some View {
        VStack(spacing: 16) {
            ResultPlayer(
                url: url,
                aspect: model.aspect,
                isPlaying: model.isPlaying,
                onTap: model.togglePlayback,
                onReplace: replace
            )
            .overlay { saveCard }
            .frame(maxHeight: .infinity)
            HStack(spacing: 16) {
                Button {
                    Task { await model.share() }
                } label: {
                    Text("Share")
                        .font(AppFont.headline)
                        .foregroundStyle(Color.appAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppMetrics.buttonHeight)
                        .background(Color.appSurface.opacity(0.6), in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
                }
                .buttonStyle(PressableButtonStyle())
                GradientButton(title: "Download", isLoading: model.isSaving) {
                    Task { await model.save() }
                }
            }
        }
        .padding(.horizontal, AppMetrics.sideInset)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var saveCard: some View {
        if let result = model.saveResult {
            SaveResultCard(result: result)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .task(id: result) {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { model.saveResult = nil }
                }
        }
    }
    
    private func replace() {
        Task {
            if await photoAccess.requestAccess() { isPickerPresented = true }
        }
    }
}

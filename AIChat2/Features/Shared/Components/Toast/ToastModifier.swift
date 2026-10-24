//
//  ToastModifier.swift
//  AIChat2
//

import SwiftUI

struct ToastModifier: ViewModifier {
    @Binding var message: ToastMessage?
    let duration: Duration
    @State private var dragOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            if let current = message {
                ToastView(message: current)
                    .offset(y: min(dragOffset, 0))
                    .gesture(
                        DragGesture()
                            .onChanged { dragOffset = $0.translation.height }
                            .onEnded { value in
                                if value.translation.height < -20 { dismiss(current) }
                                withAnimation(.spring()) { dragOffset = 0 }
                            }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .task(id: current.id) {
                        try? await Task.sleep(for: duration)
                        dismiss(current)
                    }
                    .padding(.top, 4)
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: message)
    }
    
    private func dismiss(_ shown: ToastMessage) {
        guard message?.id == shown.id else { return }
        message = nil
    }
}

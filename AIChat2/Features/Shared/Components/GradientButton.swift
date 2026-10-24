//
//  GradientButton.swift
//  AIChat2
//

import SwiftUI

struct GradientButton: View {
    
    let title: LocalizedStringKey
    var isEnabled = true
    var isLoading = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title)
                    .font(AppFont.headline)
                    .opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView().tint(.appAccent)
                }
            }
            .foregroundStyle(Color.appAccent)
            .frame(maxWidth: .infinity)
            .frame(height: AppMetrics.buttonHeight)
            .background(AppGradient.primary, in: RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .opacity(isEnabled ? 1 : 0.3)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(!isEnabled || isLoading)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }
}

#Preview {
    GradientButton(title: "next", action: {})
    GradientButton(title: "next", isEnabled: false, action: {})
    GradientButton(title: "next", isLoading: true, action: {})
}

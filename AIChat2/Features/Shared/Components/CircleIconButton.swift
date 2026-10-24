//
//  CircleIconButton.swift
//  AIChat2
//

import SwiftUI

/// Круглая кнопка 40pt на подложке 8% белого (история, настройки, меню чата).
struct CircleIconButton<Icon: View>: View {
    let label: LocalizedStringKey
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon
    
    var body: some View {
        Button(action: action) {
            icon()
                .frame(width: 24, height: 24)
                .frame(width: 40, height: 40)
                .background(Color.appFillTertiary, in: Circle())
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel(Text(label))
    }
}

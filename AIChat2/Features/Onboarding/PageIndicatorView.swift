//
//  PageIndicatorView.swift
//  AIChat2
//

import SwiftUI

struct PageIndicatorView: View {
    let count: Int
    let selection: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { index in
                let isActive = index == selection
                Capsule()
                    .fill(isActive ? AnyShapeStyle(AppGradient.primary) : AnyShapeStyle(Color.white.opacity(0.25)))
                    .frame(width: isActive ? 22 : 8, height: 8)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selection)
        .accessibilityElement()
        .accessibilityLabel(Text("Page \(selection + 1) of \(count)"))
    }
}

#Preview {
    PageIndicatorView(count: 3, selection: 1)
}

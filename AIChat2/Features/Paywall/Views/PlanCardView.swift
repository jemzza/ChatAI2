//
//  PlanCardView.swift
//  AIChat2
//

import SwiftUI

struct PlanCardView: View {
    
    let option: PlanOption
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 2) {
                        title.font(AppFont.bodyMedium)
                        if option.weeklyPrice != nil {
                            Text("/ week").font(AppFont.body)
                        }
                    }
                    .foregroundStyle(Color.appAccent)
                    Text(option.totalPrice)
                        .font(AppFont.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer(minLength: 8)
                if isSelected, let savings = option.savingsPercent {
                    Text("SAVE \(savings)%")
                        .font(AppFont.subheadlineMedium)
                        .foregroundStyle(Color.appAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(AppGradient.primary, in: Capsule())
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(border)
            .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var title: Text {
        let price = option.weeklyPrice ?? option.totalPrice
        switch option.period {
            case .year: return Text("Year \(price)")
            case .month: return Text("Month \(price)")
            case .week: return Text("Week \(price)")
            case .other: return Text("Lifetime \(price)")
        }
    }
    
    @ViewBuilder
    private var border: some View {
        let shape = RoundedRectangle(cornerRadius: AppMetrics.cardRadius)
        if isSelected {
            shape.strokeBorder(AppGradient.primary, lineWidth: 1)
        } else {
            shape.strokeBorder(Color.appStroke, lineWidth: 1)
        }
    }
}

#Preview {
    PlanCardView(option: .init(id: "monthly", period: .month, weeklyPrice: "30", totalPrice: "30", savingsPercent: 10), isSelected: true) {}
}

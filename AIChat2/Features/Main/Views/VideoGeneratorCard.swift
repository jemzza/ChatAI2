//
//  VideoGeneratorCard.swift
//  AIChat2
//

import SwiftUI

/// Карточка «Turn Photo into Video» — вход в генератор видео.
struct VideoGeneratorCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image("IconImageToImageWhite")
                    .frame(width: 20, height: 20)
                    .padding(8)
                    .background(Color.white.opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 8) {
                    Text("Turn Photo\ninto Video")
                        .font(AppFont.title3Medium)
                        .foregroundStyle(Color.appAccent)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 8) {
                        Text("Animate")
                        Circle().frame(width: 4, height: 4)
                        Text("Templates")
                    }
                    .font(AppFont.subheadline)
                    .foregroundStyle(Color.appAccent)
                    .opacity(0.7)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 189, alignment: .topLeading)
            .background(alignment: .topLeading) { background }
            .overlay(alignment: .topTrailing) { readyBadge }
            .clipShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
            .contentShape(RoundedRectangle(cornerRadius: AppMetrics.cardRadius))
        }
        .buttonStyle(PressableButtonStyle())
    }
    
    private var background: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [.appGradientStart.opacity(0.8), .appGradientEnd.opacity(0.8)],
                startPoint: UnitPoint(x: 0.2, y: 0),
                endPoint: UnitPoint(x: 0.8, y: 1)
            )
            Image("VideoCardArt")
                .resizable()
                .scaledToFill()
                .frame(width: 240, height: 360)
                .opacity(0.5)
                .offset(x: 132, y: -69)
                .accessibilityHidden(true)
        }
    }
    
    private var readyBadge: some View {
        HStack(spacing: 8) {
            Text("Ready in seconds")
                .font(AppFont.caption)
                .tracking(0.06)
            Image(systemName: "play.fill")
                .font(.system(size: 11))
        }
        .foregroundStyle(Color.appAccent)
        .padding(.horizontal, 12)
        .frame(height: 32)
        .background(Color.white.opacity(0.3), in: Capsule())
        .padding(20)
    }
}

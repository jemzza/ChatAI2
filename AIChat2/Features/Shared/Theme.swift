import SwiftUI

extension ShapeStyle where Self == Color {
    static var appBackground: Color { Color("Background") }
    static var appSurface: Color { Color("Surface") }
    static var appAccent: Color { Color("Accent") }
    static var appTextSecondary: Color { Color("TextSecondary") }
    static var appLabelTertiary: Color { .white.opacity(0.6) }
    static var appStroke: Color { .white.opacity(0.3) }
    static var appFillTertiary: Color { .white.opacity(0.08) }
    static var appSeparator: Color { .white.opacity(0.16) }
    static var appFillQuaternary: Color { .white.opacity(0.14) }
    static var appGradientStart: Color { Color("GradientStart") }
    static var appGradientEnd: Color { Color("GradientEnd") }
}

enum AppGradient {
    static let primary = LinearGradient(
        colors: [.appGradientStart, .appGradientEnd],
        startPoint: .leading, endPoint: .trailing
    )
}

enum AppFont {
    static let largeTitle = inter("Inter-Bold", 34, relativeTo: .largeTitle)
    static let title = inter("Inter-Bold", 28, relativeTo: .title)
    static let title3 = inter("Inter-SemiBold", 20, relativeTo: .title3)
    static let title3Medium = inter("Inter-Medium", 20, relativeTo: .title3)
    static let navigationTitle = inter("Inter-SemiBold", 18, relativeTo: .headline)
    static let headline = inter("Inter-SemiBold", 16, relativeTo: .headline)
    static let bodyMedium = inter("Inter-Medium", 16, relativeTo: .body)
    static let bodySemibold = inter("Inter-SemiBold", 16, relativeTo: .body)
    static let bodyBold = inter("Inter-Bold", 16, relativeTo: .body)
    static let body = inter("Inter-Regular", 16, relativeTo: .body)
    static let subheadlineMedium = inter("Inter-Medium", 14, relativeTo: .subheadline)
    static let subheadline = inter("Inter-Regular", 14, relativeTo: .subheadline)
    static let caption = inter("Inter-Regular", 12, relativeTo: .caption)
    static let captionMedium = inter("Inter-Medium", 12, relativeTo: .caption)
    static let systemCaption = Font.system(size: 12)
    static let systemCaption2 = Font.system(size: 11)
    
    private static func inter(_ name: String, _ size: CGFloat, relativeTo style: Font.TextStyle) -> Font {
        .custom(name, size: size, relativeTo: style)
    }
}

enum AppMetrics {
    static let sideInset: CGFloat = 16
    static let cellSpacing: CGFloat = 8
    static let sectionSpacing: CGFloat = 28
    static let cardRadius: CGFloat = 24
    static let rowRadius: CGFloat = 16
    static let rowHeight: CGFloat = 44
    static let chipRadius: CGFloat = 32
    static let buttonHeight: CGFloat = 50
}

enum TextStyle {
    case assistantMessage
    case userMessage
    case chatTitle
    case caption
    
    var font: Font {
        switch self {
            case .assistantMessage, .userMessage: AppFont.subheadline
            case .chatTitle: AppFont.headline
            case .caption: AppFont.caption
        }
    }
}

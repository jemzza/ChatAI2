import SwiftUI

struct MarkdownView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(MarkdownParser.parse(text).enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
            case let .heading(text):
                title(text)
            case let .paragraph(text):
                if let bold = Self.boldLine(text) {
                    title(bold)
                } else {
                    InlineText(text)
                }
            case let .list(ordered, items):
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(ordered ? "\(index + 1)." : "•")
                                .font(AppFont.body)
                                .monospacedDigit()
                            InlineText(item)
                        }
                    }
                }
            case let .code(code):
                CodeBlock(code: code)
            case let .quote(text):
                InlineText(text)
                    .opacity(0.7)
                    .padding(.leading, 12)
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.white.opacity(0.3))
                            .frame(width: 3)
                    }
        }
    }
    
    private func title(_ text: String) -> some View {
        InlineText(text, font: AppFont.bodyBold)
            .foregroundStyle(AppGradient.primary)
            .accessibilityAddTraits(.isHeader)
    }
    
    private static func boldLine(_ text: String) -> String? {
        guard text.hasPrefix("**"), text.hasSuffix("**"), text.count > 4 else { return nil }
        let inner = String(text.dropFirst(2).dropLast(2))
        return inner.contains("**") || inner.contains("\n") ? nil : inner
    }
}

private struct InlineText: View {
    let source: String
    let font: Font
    
    init(_ source: String, font: Font = AppFont.body) {
        self.source = source
        self.font = font
    }
    
    var body: some View {
        Text(attributed)
            .font(font)
            .lineSpacing(3)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private var attributed: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard var text = try? AttributedString(markdown: source, options: options) else {
            return AttributedString(source)
        }
        for run in text.runs {
            guard let intent = run.inlinePresentationIntent else { continue }
            if intent.contains(.code) {
                text[run.range].font = .system(size: 15, design: .monospaced)
            } else if intent.contains(.stronglyEmphasized) {
                text[run.range].font = AppFont.bodySemibold
                text[run.range].foregroundColor = .white
            }
        }
        return text
    }
}

private struct CodeBlock: View {
    let code: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Text(code)
                .font(.system(size: 14, design: .monospaced))
                .textSelection(.enabled)
                .fixedSize(horizontal: true, vertical: true)
                .padding(12)
        }
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.1)))
    }
}

import Foundation

nonisolated enum MarkdownBlock: Hashable, Sendable {
    case heading(String)
    case paragraph(String)
    case list(ordered: Bool, items: [String])
    case code(String)
    case quote(String)
}

nonisolated enum MarkdownParser {
    static func parse(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraph: [String] = []
        var quote: [String] = []
        var list: (ordered: Bool, items: [String])?
        var code: [String]?
        
        func flush() {
            if !paragraph.isEmpty { blocks.append(.paragraph(paragraph.joined(separator: "\n"))) }
            if !quote.isEmpty { blocks.append(.quote(quote.joined(separator: "\n"))) }
            if let list { blocks.append(.list(ordered: list.ordered, items: list.items)) }
            paragraph = []
            quote = []
            list = nil
        }
        
        for rawLine in text.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline) {
            let line = String(rawLine)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("```") {
                if let lines = code {
                    blocks.append(.code(lines.joined(separator: "\n")))
                    code = nil
                } else {
                    flush()
                    code = []
                }
                continue
            }
            if code != nil {
                code?.append(line)
                continue
            }
            if trimmed.isEmpty {
                flush()
            } else if let heading = heading(trimmed) {
                flush()
                blocks.append(.heading(heading))
            } else if trimmed.hasPrefix(">") {
                quote.append(trimmed.dropFirst().trimmingCharacters(in: .whitespaces))
            } else if let item = listItem(trimmed) {
                if list?.ordered != item.ordered {
                    flush()
                    list = (item.ordered, [])
                }
                paragraph = []
                list?.items.append(item.text)
            } else if list != nil, line.hasPrefix("  "), let last = list?.items.indices.last {
                list?.items[last] += "\n" + trimmed
            } else {
                if list != nil { flush() }
                paragraph.append(trimmed)
            }
        }
        if let lines = code { blocks.append(.code(lines.joined(separator: "\n"))) }
        flush()
        return blocks
    }
    
    static func plainText(_ text: String) -> String {
        parse(String(text.prefix(400)))
            .map { block in
                switch block {
                    case let .heading(text), let .paragraph(text), let .quote(text): inline(text)
                    case let .list(_, items): items.map(inline).joined(separator: " ")
                    case let .code(code): code
                }
            }
            .joined(separator: " ")
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }
    
    private static func inline(_ text: String) -> String {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        guard let attributed = try? AttributedString(markdown: text, options: options) else { return text }
        return String(attributed.characters)
    }
    
    private static func heading(_ line: String) -> String? {
        let hashes = line.prefix { $0 == "#" }.count
        guard (1...6).contains(hashes), line.dropFirst(hashes).first == " " else { return nil }
        return line.dropFirst(hashes).trimmingCharacters(in: .whitespaces)
    }
    
    private static func listItem(_ line: String) -> (ordered: Bool, text: String)? {
        if let marker = line.first, "-*+".contains(marker), line.dropFirst().first == " " {
            return (false, line.dropFirst(2).trimmingCharacters(in: .whitespaces))
        }
        let digits = line.prefix { $0.isNumber }
        let rest = line.dropFirst(digits.count)
        guard !digits.isEmpty, rest.hasPrefix(". ") || rest.hasPrefix(") ") else { return nil }
        return (true, rest.dropFirst(2).trimmingCharacters(in: .whitespaces))
    }
}

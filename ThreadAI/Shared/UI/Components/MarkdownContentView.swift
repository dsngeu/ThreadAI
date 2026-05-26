import SwiftUI

struct MarkdownContentView: View {
    let content: String

    var body: some View {
        let blocks = MarkdownBlockParser.parse(content)
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownBlock) -> some View {
        switch block {
        case .paragraph(let text):
            inlineMarkdown(text)
        case .header(let text, let level):
            headerView(text, level: level)
        case .bulletItem(let text):
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text("•")
                    .font(AppTypography.messageBubble)
                    .foregroundStyle(AppColors.textSecondary)
                inlineMarkdown(text)
            }
            .padding(.leading, AppSpacing.sm)
        case .orderedItem(let text, let index):
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text("\(index).")
                    .font(AppTypography.messageBubble)
                    .foregroundStyle(AppColors.textSecondary)
                    .monospacedDigit()
                inlineMarkdown(text)
            }
            .padding(.leading, AppSpacing.sm)
        case .code(let code, let language):
            CodeBlockView(code: code, language: language)
        case .blockquote(let text):
            HStack(spacing: AppSpacing.sm) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppColors.accent.opacity(0.5))
                    .frame(width: 3)
                inlineMarkdown(text)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.leading, AppSpacing.xs)
        }
    }

    private func headerView(_ text: String, level: Int) -> some View {
        let font: Font = switch level {
        case 1: AppTypography.title2
        case 2: AppTypography.title3
        default: AppTypography.headline
        }
        return Text(text)
            .font(font)
            .foregroundStyle(AppColors.textPrimary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func inlineMarkdown(_ text: String) -> some View {
        Text(renderMarkdown(text))
            .font(AppTypography.messageBubble)
            .foregroundStyle(AppColors.textPrimary)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func renderMarkdown(_ input: String) -> AttributedString {
        InlineMarkdownRenderer.render(input)
    }
}

// MARK: - Shared Inline Markdown Renderer

enum InlineMarkdownRenderer {
    static func render(_ input: String) -> AttributedString {
        if let result = try? AttributedString(
            markdown: input,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return result
        }
        if let result = try? AttributedString(markdown: input) {
            return result
        }
        return manualParse(input)
    }

    private static func manualParse(_ input: String) -> AttributedString {
        var result = AttributedString()
        var remaining = input[...]

        while !remaining.isEmpty {
            if let boldRange = remaining.range(of: "**") {
                let before = String(remaining[remaining.startIndex..<boldRange.lowerBound])
                if !before.isEmpty { result += AttributedString(before) }
                let afterOpen = remaining[boldRange.upperBound...]
                if let closeRange = afterOpen.range(of: "**") {
                    var bold = AttributedString(String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound]))
                    bold.inlinePresentationIntent = .stronglyEmphasized
                    result += bold
                    remaining = afterOpen[closeRange.upperBound...]
                    continue
                } else {
                    result += AttributedString(String(remaining))
                    break
                }
            } else if let italicRange = remaining.range(of: "*") {
                let before = String(remaining[remaining.startIndex..<italicRange.lowerBound])
                if !before.isEmpty { result += AttributedString(before) }
                let afterOpen = remaining[italicRange.upperBound...]
                if let closeRange = afterOpen.range(of: "*") {
                    var italic = AttributedString(String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound]))
                    italic.inlinePresentationIntent = .emphasized
                    result += italic
                    remaining = afterOpen[closeRange.upperBound...]
                    continue
                } else {
                    result += AttributedString(String(remaining))
                    break
                }
            } else if let codeRange = remaining.range(of: "`") {
                let before = String(remaining[remaining.startIndex..<codeRange.lowerBound])
                if !before.isEmpty { result += AttributedString(before) }
                let afterOpen = remaining[codeRange.upperBound...]
                if let closeRange = afterOpen.range(of: "`") {
                    var code = AttributedString(String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound]))
                    code.inlinePresentationIntent = .code
                    result += code
                    remaining = afterOpen[closeRange.upperBound...]
                    continue
                } else {
                    result += AttributedString(String(remaining))
                    break
                }
            } else {
                result += AttributedString(String(remaining))
                break
            }
        }

        return result
    }
}

// MARK: - Block Types

enum MarkdownBlock {
    case paragraph(String)
    case header(String, level: Int)
    case bulletItem(String)
    case orderedItem(String, index: Int)
    case code(String, language: String?)
    case blockquote(String)
}

// MARK: - Block Parser

enum MarkdownBlockParser {
    static func parse(_ input: String) -> [MarkdownBlock] {
        let rawSegments = splitCodeBlocks(input)
        var blocks: [MarkdownBlock] = []

        for segment in rawSegments {
            switch segment {
            case .code(let code, let language):
                blocks.append(.code(code, language: language))
            case .text(let text):
                blocks.append(contentsOf: parseTextBlocks(text))
            }
        }

        return blocks
    }

    private static func parseTextBlocks(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        var paragraphLines: [String] = []

        func flushParagraph() {
            let joined = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !joined.isEmpty {
                blocks.append(.paragraph(joined))
            }
            paragraphLines.removeAll()
        }

        let lines = text.components(separatedBy: "\n")

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                flushParagraph()
                continue
            }

            if let headerMatch = parseHeader(trimmed) {
                flushParagraph()
                blocks.append(headerMatch)
                continue
            }

            if let bulletMatch = parseBulletItem(trimmed) {
                flushParagraph()
                blocks.append(bulletMatch)
                continue
            }

            if let orderedMatch = parseOrderedItem(trimmed) {
                flushParagraph()
                blocks.append(orderedMatch)
                continue
            }

            if let quoteMatch = parseBlockquote(trimmed) {
                flushParagraph()
                blocks.append(quoteMatch)
                continue
            }

            paragraphLines.append(line)
        }

        flushParagraph()
        return blocks
    }

    private static func parseHeader(_ line: String) -> MarkdownBlock? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#" {
            level += 1
            idx = line.index(after: idx)
        }
        guard level >= 1, level <= 6, idx < line.endIndex, line[idx] == " " else { return nil }
        let text = String(line[line.index(after: idx)...]).trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return .header(text, level: level)
    }

    private static func parseBulletItem(_ line: String) -> MarkdownBlock? {
        guard line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("• ") else { return nil }
        let text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
        return .bulletItem(text)
    }

    private static func parseOrderedItem(_ line: String) -> MarkdownBlock? {
        guard let dotIndex = line.firstIndex(of: ".") else { return nil }
        let numberPart = line[line.startIndex..<dotIndex]
        guard let number = Int(numberPart), number > 0 else { return nil }
        let afterDot = line.index(after: dotIndex)
        guard afterDot < line.endIndex, line[afterDot] == " " else { return nil }
        let text = String(line[line.index(after: afterDot)...]).trimmingCharacters(in: .whitespaces)
        return .orderedItem(text, index: number)
    }

    private static func parseBlockquote(_ line: String) -> MarkdownBlock? {
        guard line.hasPrefix("> ") else { return nil }
        let text = String(line.dropFirst(2))
        return .blockquote(text)
    }

    // MARK: - Code Block Splitting

    private enum RawSegment {
        case text(String)
        case code(String, language: String?)
    }

    private static func splitCodeBlocks(_ input: String) -> [RawSegment] {
        var result: [RawSegment] = []
        var remaining = input[...]

        while !remaining.isEmpty {
            guard let openRange = remaining.range(of: "```") else {
                result.append(.text(String(remaining)))
                break
            }

            let beforeCode = String(remaining[..<openRange.lowerBound])
            if !beforeCode.isEmpty { result.append(.text(beforeCode)) }

            let afterOpen = remaining[openRange.upperBound...]

            let language: String?
            let codeBodyStart: String.SubSequence
            if let newline = afterOpen.firstIndex(of: "\n") {
                let lang = String(afterOpen[..<newline]).trimmingCharacters(in: .whitespaces)
                language = lang.isEmpty ? nil : lang
                codeBodyStart = afterOpen[afterOpen.index(after: newline)...]
            } else {
                language = nil
                codeBodyStart = afterOpen
            }

            if let closeRange = codeBodyStart.range(of: "```") {
                let code = String(codeBodyStart[..<closeRange.lowerBound])
                result.append(.code(code, language: language))
                remaining = codeBodyStart[closeRange.upperBound...]
            } else {
                result.append(.text("```" + String(afterOpen)))
                break
            }
        }

        return result
    }
}

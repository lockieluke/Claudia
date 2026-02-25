//
//  MarkdownLatexView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
internal import SwiftUIMath
import AppKit

/// Represents a run of consecutive blocks that can be rendered together.
/// Consecutive pure-text paragraphs are merged into a single `SelectableTextView`
/// so that text selection works across paragraph boundaries.
private enum RenderGroup: Identifiable {
    case textRun(id: String, markdown: String)
    case mathParagraph(id: String, inlines: [InlineSegment])
    case displayMath(id: String, tex: String)
    case heading(id: String, level: Int, text: String)
    case codeBlock(id: String, language: String?, code: String)
    case horizontalRule(id: String)
    case list(id: String, items: [ListItem])
    
    var id: String {
        switch self {
        case .textRun(let id, _): return "tr:\(id)"
        case .mathParagraph(let id, _): return "mp:\(id)"
        case .displayMath(let id, _): return "dm:\(id)"
        case .heading(let id, _, _): return "h:\(id)"
        case .codeBlock(let id, _, _): return "cb:\(id)"
        case .horizontalRule(let id): return "hr:\(id)"
        case .list(let id, _): return "li:\(id)"
        }
    }
}

/// Groups consecutive pure-text paragraphs into single text runs for unified selection.
private func groupBlocks(_ blocks: [BlockSegment]) -> [RenderGroup] {
    var groups: [RenderGroup] = []
    var pendingTexts: [String] = []
    var pendingId = ""
    
    func flushTexts() {
        guard !pendingTexts.isEmpty else { return }
        let markdown = pendingTexts.joined(separator: "\n\n")
        groups.append(.textRun(id: pendingId, markdown: markdown))
        pendingTexts = []
        pendingId = ""
    }
    
    for block in blocks {
        switch block {
        case .paragraph(let inlines):
            let isPureText = inlines.allSatisfy { if case .text = $0 { return true }; return false }
            if isPureText {
                let combined = inlines.map { if case .text(let t) = $0 { return t }; return "" }.joined(separator: " ")
                if pendingTexts.isEmpty {
                    pendingId = block.id
                }
                pendingTexts.append(combined)
            } else {
                flushTexts()
                groups.append(.mathParagraph(id: block.id, inlines: inlines))
            }
        case .displayMath(let tex):
            flushTexts()
            groups.append(.displayMath(id: block.id, tex: tex))
        case .heading(let level, let text):
            flushTexts()
            groups.append(.heading(id: block.id, level: level, text: text))
        case .codeBlock(let language, let code):
            flushTexts()
            groups.append(.codeBlock(id: block.id, language: language, code: code))
        case .horizontalRule:
            flushTexts()
            groups.append(.horizontalRule(id: block.id))
        case .list(let items):
            flushTexts()
            groups.append(.list(id: block.id, items: items))
        }
    }
    
    flushTexts()
    return groups
}

public struct MarkdownLatexView: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let text: String
    private let fontSize: CGFloat
    private let lineHeight: CGFloat
    private let blocks: [BlockSegment]
    
    public init(_ text: String, fontSize: CGFloat = 15, lineHeight: CGFloat = 24) {
        self.text = text
        self.fontSize = fontSize
        self.lineHeight = lineHeight
        self.blocks = ParsedBlocksCache.shared.blocks(for: text)
    }
    
    public var body: some View {
        let groups = groupBlocks(blocks)
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(groups) { group in
                switch group {
                case .textRun(_, let markdown):
                    TextRunView(markdown: markdown, fontSize: fontSize, lineHeight: lineHeight, colorScheme: colorScheme)
                    
                case .mathParagraph(_, let inlines):
                    FlowLayout(spacing: 2) {
                        ForEach(inlines) { inline in
                            switch inline {
                            case .text(let md):
                                Text(LocalizedStringKey(md))
                                    .font(.serifFont(size: fontSize))
                                    .textSelection(.enabled)
                                    .confirmExternalLinks()
                            case .math(let tex):
                                Math(tex)
                                    .mathFont(Math.Font(name: .latinModern, size: fontSize))
                                    .mathRenderingMode(.monochrome)
                                    .foregroundStyle(colorScheme == .dark ? .white : .black)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    
                case .displayMath(_, let tex):
                    Math(tex)
                        .mathFont(Math.Font(name: .latinModern, size: fontSize + 2))
                        .mathTypesettingStyle(.display)
                        .mathRenderingMode(.monochrome)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                    
                case .heading(_, let level, let headingText):
                    HeadingView(text: headingText, level: level, fontSize: fontSize, colorScheme: colorScheme)
                    
                case .codeBlock(_, let language, let code):
                    CodeBlockView(code: code, language: language, colorScheme: colorScheme, fontSize: fontSize)
                    
                case .horizontalRule:
                    Divider()
                        .padding(.vertical, 4)
                    
                case .list(_, let items):
                    ListBlockView(items: items, fontSize: fontSize, lineHeight: lineHeight, colorScheme: colorScheme)
                }
            }
        }
        .enableInjection()
    }
}

/// Renders a run of pure-text markdown paragraphs.
private struct TextRunView: View {
    let markdown: String
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let colorScheme: ColorScheme
    
    var body: some View {
        let nsFont = NSFont(name: "Anthropic Serif Web Text", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)
        let attrString = markdownAttributedString(markdown, font: nsFont, lineHeight: lineHeight, colorScheme: colorScheme)
        SelectableTextView(attributedString: attrString)
    }
}

/// Renders a markdown heading at the appropriate size.
private struct HeadingView: View {
    let text: String
    let level: Int
    let fontSize: CGFloat
    let colorScheme: ColorScheme
    
    var body: some View {
        let headingSize: CGFloat = switch level {
            case 1: fontSize + 10
            case 2: fontSize + 6
            case 3: fontSize + 3
            default: fontSize + 1
        }
        let nsFont = NSFont(name: "AnthropicSerifWebVariable-TextSemibold", size: headingSize)
            ?? NSFont.boldSystemFont(ofSize: headingSize)
        let attrString = markdownAttributedString(text, font: nsFont, lineHeight: headingSize + 8, colorScheme: colorScheme)
        SelectableTextView(attributedString: attrString)
            .padding(.top, level <= 2 ? 8 : 4)
    }
}

/// Renders a fenced code block with a dark/light background, optional language label,
/// and selectable monospaced text.
private struct CodeBlockView: View {
    let code: String
    let language: String?
    let colorScheme: ColorScheme
    let fontSize: CGFloat
    
    private var codeAttributedString: NSAttributedString {
        let monoFont = NSFont.monospacedSystemFont(ofSize: fontSize - 1, weight: .regular)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.minimumLineHeight = fontSize + 6
        paragraphStyle.maximumLineHeight = fontSize + 6
        let fgColor: NSColor = colorScheme == .dark ? .white.withAlphaComponent(0.9) : .black.withAlphaComponent(0.9)
        return NSAttributedString(string: code, attributes: [
            .font: monoFont,
            .foregroundColor: fgColor,
            .paragraphStyle: paragraphStyle,
        ])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let language, !language.isEmpty {
                Text(language)
                    .font(.sansFont(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            SelectableTextView(attributedString: codeAttributedString)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
         .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark
                      ? Color.white.opacity(0.06)
                      : Color.black.opacity(0.04))
        )
    }
}

/// Renders a list of items with bullets or numbers, supporting nesting.
private struct ListBlockView: View {
    let items: [ListItem]
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(items) { item in
                ListItemView(item: item, fontSize: fontSize, lineHeight: lineHeight, colorScheme: colorScheme)
            }
        }
    }
}

/// Renders a single list item row with the bullet baked into the attributed string.
private struct ListItemView: View {
    let item: ListItem
    let fontSize: CGFloat
    let lineHeight: CGFloat
    let colorScheme: ColorScheme
    
    private var bullet: String {
        item.ordered ? "\(item.ordinal)." : (item.indent == 0 ? "\u{2022}" : "\u{25E6}")
    }
    
    private var itemAttributedString: NSAttributedString {
        let nsFont = NSFont(name: "Anthropic Serif Web Text", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize)
        // Prepend bullet with a tab, use hanging indent so wrapped lines align
        let bulletPrefix = "\(bullet)\t"
        let fullMarkdown = "\(bulletPrefix)\(item.text)"
        let attrString = markdownAttributedString(fullMarkdown, font: nsFont, lineHeight: lineHeight, colorScheme: colorScheme)
        
        // Apply hanging indent paragraph style
        let mutable = NSMutableAttributedString(attributedString: attrString)
        let tabStop: CGFloat = item.ordered ? 24 : 16
        let fullRange = NSRange(location: 0, length: mutable.length)
        mutable.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
            let para = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle
                ?? NSMutableParagraphStyle()
            para.headIndent = tabStop
            para.firstLineHeadIndent = 0
            para.tabStops = [NSTextTab(textAlignment: .left, location: tabStop)]
            para.minimumLineHeight = lineHeight
            para.maximumLineHeight = lineHeight
            mutable.addAttribute(.paragraphStyle, value: para, range: range)
        }
        return mutable
    }
    
    var body: some View {
        SelectableTextView(attributedString: itemAttributedString)
            .padding(.leading, CGFloat(item.indent) * 20)
    }
}

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
    
    var id: String {
        switch self {
        case .textRun(let id, _): return "tr:\(id)"
        case .mathParagraph(let id, _): return "mp:\(id)"
        case .displayMath(let id, _): return "dm:\(id)"
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
                    let nsFont = NSFont(name: "Anthropic Serif Web Text", size: fontSize)
                        ?? NSFont.systemFont(ofSize: fontSize)
                    let attrString = markdownAttributedString(markdown, font: nsFont, lineHeight: lineHeight, colorScheme: colorScheme)
                    SelectableTextView(attributedString: attrString)
                    
                case .mathParagraph(_, let inlines):
                    // Mixed text + inline math — use flow layout
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
                }
            }
        }
        .enableInjection()
    }
}

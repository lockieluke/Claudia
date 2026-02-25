//
//  MarkdownLatexView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SwiftUIMath
import Foundation

enum InlineSegment: Identifiable {
    case text(String)
    case math(String)
    
    var id: String {
        switch self {
        case .text(let t): return "t:\(t)"
        case .math(let m): return "m:\(m)"
        }
    }
}

enum BlockSegment: Identifiable {
    case paragraph([InlineSegment])
    case displayMath(String)
    
    var id: String {
        switch self {
        case .paragraph(let segs): return "p:\(segs.map(\.id).joined())"
        case .displayMath(let tex): return "dm:\(tex)"
        }
    }
}

/// Parses a string containing mixed markdown and LaTeX into block-level segments.
/// Inline math (`$...$`, `\(...\)`) stays within paragraphs.
/// Display math (`$$...$$`, `\[...\]`) and double newlines create block breaks.
func parseContent(_ text: String) -> [BlockSegment] {
    // Ordered so that `$$` and `\[` are checked before `$` and `\(`
    let delimiters: [(open: String, close: String, type: String)] = [
        ("\\[", "\\]", "display"),
        ("$$", "$$", "display"),
        ("\\(", "\\)", "inline"),
        ("$", "$", "inline"),
    ]
    
    var blocks: [BlockSegment] = []
    var currentInline: [InlineSegment] = []
    var i = text.startIndex
    var textStart = i
    
    func flushText(upTo end: String.Index) {
        guard textStart < end else { return }
        let t = String(text[textStart..<end])
        // Split on double newlines for paragraph breaks
        let paragraphs = t.components(separatedBy: "\n\n")
        for (idx, para) in paragraphs.enumerated() {
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                currentInline.append(.text(trimmed))
            }
            // Paragraph break between parts — flush current inline as a block
            if idx < paragraphs.count - 1 && !currentInline.isEmpty {
                blocks.append(.paragraph(currentInline))
                currentInline = []
            }
        }
    }
    
    func flushInline() {
        guard !currentInline.isEmpty else { return }
        blocks.append(.paragraph(currentInline))
        currentInline = []
    }
    
    while i < text.endIndex {
        var matched = false
        
        for delimiter in delimiters {
            let open = delimiter.open
            let close = delimiter.close
            
            guard let openEnd = text.index(i, offsetBy: open.count, limitedBy: text.endIndex),
                  text[i..<openEnd] == open else {
                continue
            }
            
            // For single `$`, disambiguate from `$$`
            if open == "$" && openEnd < text.endIndex && text[openEnd] == "$" {
                continue
            }
            
            // Search for the closing delimiter
            var searchFrom = openEnd
            var closeRange: Range<String.Index>? = nil
            
            while searchFrom < text.endIndex {
                guard let found = text.range(of: close, range: searchFrom..<text.endIndex) else {
                    break
                }
                
                if close == "$" && open == "$" {
                    let afterClose = found.upperBound
                    if afterClose < text.endIndex && text[afterClose] == "$" {
                        searchFrom = text.index(afterClose, offsetBy: 1, limitedBy: text.endIndex) ?? text.endIndex
                        continue
                    }
                }
                
                closeRange = found
                break
            }
            
            guard let closeFound = closeRange else {
                continue
            }
            
            // Flush any text before this delimiter
            flushText(upTo: i)
            
            let latex = String(text[openEnd..<closeFound.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if delimiter.type == "display" {
                flushInline()
                if !latex.isEmpty {
                    blocks.append(.displayMath(latex))
                }
            } else {
                if !latex.isEmpty {
                    currentInline.append(.math(latex))
                }
            }
            
            i = closeFound.upperBound
            textStart = i
            matched = true
            break
        }
        
        if !matched {
            i = text.index(after: i)
        }
    }
    
    // Flush remaining text and inline segments
    flushText(upTo: text.endIndex)
    flushInline()
    
    return blocks
}

/// A wrapping flow layout that places inline content on the same line,
/// breaking to the next line when the available width is exceeded.
struct FlowLayout: Layout {
    
    var spacing: CGFloat = 4
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        
        // First pass: assign rows and compute row heights
        struct RowItem {
            var x: CGFloat
            var rowIndex: Int
            var size: CGSize
        }
        
        var items: [RowItem] = []
        var rowHeights: [CGFloat] = []
        var x: CGFloat = 0
        var rowIndex = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > maxWidth && x > 0 {
                rowHeights.append(currentRowHeight)
                x = 0
                rowIndex += 1
                currentRowHeight = 0
            }
            
            items.append(RowItem(x: x, rowIndex: rowIndex, size: size))
            currentRowHeight = max(currentRowHeight, size.height)
            x += size.width + spacing
        }
        rowHeights.append(currentRowHeight)
        
        // Second pass: compute y positions with vertical centering within each row
        var positions: [CGPoint] = []
        var rowY: [CGFloat] = [0]
        for i in 1..<rowHeights.count {
            rowY.append(rowY[i - 1] + rowHeights[i - 1] + spacing)
        }
        
        var totalWidth: CGFloat = 0
        for item in items {
            let yOffset = (rowHeights[item.rowIndex] - item.size.height) / 2
            positions.append(CGPoint(x: item.x, y: rowY[item.rowIndex] + yOffset))
            totalWidth = max(totalWidth, item.x + item.size.width)
        }
        
        let totalHeight = rowY.last.map { $0 + rowHeights.last! } ?? 0
        return (CGSize(width: totalWidth, height: totalHeight), positions)
    }
    
}

/// Thread-safe cache for parsed block segments, keyed by message text.
private final class ParsedBlocksCache {
    static let shared = ParsedBlocksCache()
    
    private let cache = NSCache<NSString, CachedBlocks>()
    
    private init() {
        cache.countLimit = 200
    }
    
    func blocks(for text: String) -> [BlockSegment] {
        let key = text as NSString
        if let cached = cache.object(forKey: key) {
            return cached.blocks
        }
        let parsed = parseContent(text)
        cache.setObject(CachedBlocks(blocks: parsed), forKey: key)
        return parsed
    }
}

/// NSCache requires reference-type values.
private final class CachedBlocks {
    let blocks: [BlockSegment]
    init(blocks: [BlockSegment]) { self.blocks = blocks }
}

public struct MarkdownLatexView: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let text: String
    private let fontSize: CGFloat
    private let blocks: [BlockSegment]
    
    public init(_ text: String, fontSize: CGFloat = 15) {
        self.text = text
        self.fontSize = fontSize
        self.blocks = ParsedBlocksCache.shared.blocks(for: text)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(blocks) { block in
                switch block {
                case .paragraph(let inlines):
                    if inlines.allSatisfy({ if case .text = $0 { return true }; return false }) {
                        // Pure text paragraph — render as a single markdown Text
                        let combined = inlines.map { if case .text(let t) = $0 { return t }; return "" }.joined(separator: " ")
                        Text(LocalizedStringKey(combined))
                            .font(.serifFont(size: fontSize))
                            .lineHeight(24, fontSize: fontSize)
                            .textSelection(.enabled)
                    } else {
                        // Mixed text + inline math — use flow layout
                        FlowLayout(spacing: 2) {
                            ForEach(inlines) { inline in
                                switch inline {
                                case .text(let md):
                                    Text(LocalizedStringKey(md))
                                        .font(.serifFont(size: fontSize))
                                        .textSelection(.enabled)
                                case .math(let tex):
                                    Math(tex)
                                        .mathFont(Math.Font(name: .latinModern, size: fontSize))
                                        .mathRenderingMode(.monochrome)
                                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                                        .padding(.horizontal, 4)
                                        .drawingGroup()
                                }
                            }
                        }
                    }
                case .displayMath(let tex):
                    Math(tex)
                        .mathFont(Math.Font(name: .latinModern, size: fontSize + 2))
                        .mathTypesettingStyle(.display)
                        .mathRenderingMode(.monochrome)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                        .drawingGroup()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 4)
                }
            }
        }
        .enableInjection()
    }
}

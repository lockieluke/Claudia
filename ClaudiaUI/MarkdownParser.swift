//
//  MarkdownParser.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

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

/// Thread-safe cache for parsed block segments, keyed by message text.
final class ParsedBlocksCache {
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

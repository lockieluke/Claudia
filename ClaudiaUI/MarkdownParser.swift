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

struct ListItem: Identifiable {
    let id = UUID()
    let text: String
    let indent: Int       // nesting level (0 = top)
    let ordered: Bool
    let ordinal: Int      // 1-based index for ordered lists
}

enum BlockSegment: Identifiable {
    case paragraph([InlineSegment])
    case displayMath(String)
    case heading(level: Int, text: String)
    case codeBlock(language: String?, code: String)
    case horizontalRule
    case list([ListItem])
    
    var id: String {
        switch self {
        case .paragraph(let segs): return "p:\(segs.map(\.id).joined())"
        case .displayMath(let tex): return "dm:\(tex)"
        case .heading(let level, let text): return "h\(level):\(text)"
        case .codeBlock(let lang, let code): return "cb:\(lang ?? ""):\(code.prefix(40))"
        case .horizontalRule: return "hr"
        case .list(let items): return "li:\(items.map(\.text).joined(separator: ",").prefix(60))"
        }
    }
}

func parseContent(_ text: String) -> [BlockSegment] {
    // Phase 1: line-based extraction of block constructs
    let rawBlocks = extractBlocks(from: text)
    
    // Phase 2: parse inline math within paragraph text
    var result: [BlockSegment] = []
    for raw in rawBlocks {
        switch raw {
        case .heading, .codeBlock, .horizontalRule, .list:
            result.append(raw)
        case .displayMath:
            result.append(raw)
        case .paragraph:
            // Re-parse paragraph text for math
            if case .paragraph(let inlines) = raw,
               let textContent = inlines.first, case .text(let str) = textContent {
                result.append(contentsOf: parseInlineMath(str))
            } else {
                result.append(raw)
            }
        }
    }
    return result
}

// MARK: - Phase 1: Block-level extraction

private func extractBlocks(from text: String) -> [BlockSegment] {
    let lines = text.components(separatedBy: "\n")
    var blocks: [BlockSegment] = []
    var paragraphLines: [String] = []
    var i = 0
    
    func flushParagraph() {
        let joined = paragraphLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !joined.isEmpty {
            blocks.append(.paragraph([.text(joined)]))
        }
        paragraphLines = []
    }
    
    while i < lines.count {
        let line = lines[i]
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        // Fenced code block: ``` or ~~~
        if trimmed.hasPrefix("```") || trimmed.hasPrefix("~~~") {
            flushParagraph()
            let fence = String(trimmed.prefix(3))
            let language = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            let lang = language.isEmpty ? nil : language
            var codeLines: [String] = []
            i += 1
            while i < lines.count {
                let codeLine = lines[i]
                if codeLine.trimmingCharacters(in: .whitespaces).hasPrefix(fence) {
                    i += 1
                    break
                }
                codeLines.append(codeLine)
                i += 1
            }
            blocks.append(.codeBlock(language: lang, code: codeLines.joined(separator: "\n")))
            continue
        }
        
        // Heading: # through ######
        if let headingMatch = matchHeading(trimmed) {
            flushParagraph()
            blocks.append(.heading(level: headingMatch.level, text: headingMatch.text))
            i += 1
            continue
        }
        
        // Horizontal rule: ---, ***, ___ (3+ chars)
        if isHorizontalRule(trimmed) {
            flushParagraph()
            blocks.append(.horizontalRule)
            i += 1
            continue
        }
        
        // List item: `- `, `* `, `+ `, `1. `
        if matchListItem(line) != nil {
            flushParagraph()
            var items: [ListItem] = []
            var orderedCounters: [Int: Int] = [:]
            while i < lines.count, let match = matchListItem(lines[i]) {
                if match.ordered {
                    orderedCounters[match.indent, default: 0] += 1
                    items.append(ListItem(text: match.text, indent: match.indent, ordered: true, ordinal: orderedCounters[match.indent]!))
                } else {
                    items.append(ListItem(text: match.text, indent: match.indent, ordered: false, ordinal: 0))
                    orderedCounters[match.indent] = nil
                }
                i += 1
            }
            blocks.append(.list(items))
            continue
        }
        
        // Empty line → flush paragraph
        if trimmed.isEmpty {
            flushParagraph()
            i += 1
            continue
        }
        
        // Otherwise: accumulate as paragraph text
        paragraphLines.append(line)
        i += 1
    }
    
    flushParagraph()
    return blocks
}

// MARK: - Phase 2: Inline math parsing within paragraphs

private func parseInlineMath(_ text: String) -> [BlockSegment] {
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
        let paragraphs = t.components(separatedBy: "\n\n")
        for (idx, para) in paragraphs.enumerated() {
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                currentInline.append(.text(trimmed))
            }
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
            
            if open == "$" && openEnd < text.endIndex && text[openEnd] == "$" {
                continue
            }
            
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
    
    flushText(upTo: text.endIndex)
    flushInline()
    
    return blocks
}

// MARK: - Helpers

private func matchHeading(_ line: String) -> (level: Int, text: String)? {
    guard let regex = try? NSRegularExpression(pattern: #"^(#{1,6})\s+(.+)$"#),
          let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
          match.numberOfRanges >= 3,
          let hashRange = Range(match.range(at: 1), in: line),
          let textRange = Range(match.range(at: 2), in: line)
    else { return nil }
    return (level: line[hashRange].count, text: String(line[textRange]))
}

private func matchListItem(_ line: String) -> (text: String, indent: Int, ordered: Bool)? {
    let indent = line.prefix(while: { $0 == " " }).count
    let level = indent / 2
    let stripped = String(line.dropFirst(indent))
    
    // Unordered: `- `, `* `, `+ `
    if (stripped.hasPrefix("- ") || stripped.hasPrefix("* ") || stripped.hasPrefix("+ ")),
       stripped.count > 2 {
        return (text: String(stripped.dropFirst(2)), indent: level, ordered: false)
    }
    
    // Ordered: `1. `, `12. `, etc.
    if let dotIndex = stripped.firstIndex(of: "."),
       dotIndex > stripped.startIndex,
       stripped[stripped.startIndex..<dotIndex].allSatisfy(\.isNumber) {
        let afterDot = stripped.index(after: dotIndex)
        if afterDot < stripped.endIndex && stripped[afterDot] == " " {
            let text = String(stripped[stripped.index(after: afterDot)...])
            return (text: text, indent: level, ordered: true)
        }
    }
    
    return nil
}

private func isHorizontalRule(_ line: String) -> Bool {
    guard let regex = try? NSRegularExpression(pattern: #"^[-*_]{3,}$"#) else { return false }
    return regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil
}

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

private final class CachedBlocks {
    let blocks: [BlockSegment]
    init(blocks: [BlockSegment]) { self.blocks = blocks }
}

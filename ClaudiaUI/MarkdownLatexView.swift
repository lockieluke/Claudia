//
//  MarkdownLatexView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SwiftUIMath

enum ContentSegment: Identifiable {
    case markdown(String)
    case inlineLatex(String)
    case displayLatex(String)
    
    var id: String {
        switch self {
        case .markdown(let text): return "md:\(text)"
        case .inlineLatex(let tex): return "il:\(tex)"
        case .displayLatex(let tex): return "dl:\(tex)"
        }
    }
}

/// Parses a string containing mixed markdown and LaTeX into segments.
/// Supports `\(...\)` for inline LaTeX, `\[...\]` and `$$...$$` for display LaTeX.
func parseContent(_ text: String) -> [ContentSegment] {
    var segments: [ContentSegment] = []
    var remaining = text[text.startIndex...]
    
    while !remaining.isEmpty {
        // Find the earliest LaTeX delimiter
        var earliestRange: Range<String.Index>? = nil
        var earliestType: String? = nil
        
        let delimiters: [(open: String, close: String, type: String)] = [
            ("\\[", "\\]", "display"),
            ("$$", "$$", "display"),
            ("\\(", "\\)", "inline"),
        ]
        
        for delimiter in delimiters {
            if let openRange = remaining.range(of: delimiter.open) {
                if earliestRange == nil || openRange.lowerBound < earliestRange!.lowerBound {
                    earliestRange = openRange
                    earliestType = delimiter.type
                }
            }
        }
        
        guard let openRange = earliestRange, let type = earliestType else {
            // No more LaTeX — rest is markdown
            let markdownText = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
            if !markdownText.isEmpty {
                segments.append(.markdown(markdownText))
            }
            break
        }
        
        // Add markdown before this LaTeX block
        let before = String(remaining[remaining.startIndex..<openRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        if !before.isEmpty {
            segments.append(.markdown(before))
        }
        
        // Find the matching close delimiter
        let afterOpen = remaining[openRange.upperBound...]
        let closeDelimiter: String
        if type == "display" {
            // Determine which open delimiter was matched
            if remaining[openRange].hasPrefix("\\[") {
                closeDelimiter = "\\]"
            } else {
                closeDelimiter = "$$"
            }
        } else {
            closeDelimiter = "\\)"
        }
        
        if let closeRange = afterOpen.range(of: closeDelimiter) {
            let latex = String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !latex.isEmpty {
                if type == "display" {
                    segments.append(.displayLatex(latex))
                } else {
                    segments.append(.inlineLatex(latex))
                }
            }
            remaining = afterOpen[closeRange.upperBound...]
        } else {
            // No closing delimiter — treat rest as markdown
            let rest = String(remaining).trimmingCharacters(in: .whitespacesAndNewlines)
            if !rest.isEmpty {
                segments.append(.markdown(rest))
            }
            break
        }
    }
    
    return segments
}

public struct MarkdownLatexView: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let text: String
    private let fontSize: CGFloat
    private let segments: [ContentSegment]
    
    public init(_ text: String, fontSize: CGFloat = 15) {
        self.text = text
        self.fontSize = fontSize
        self.segments = parseContent(text)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(segments) { segment in
                switch segment {
                case .markdown(let md):
                    Text(LocalizedStringKey(md))
                        .font(.sansFont(size: fontSize))
                        .lineSpacing(5)
                        .textSelection(.enabled)
                case .inlineLatex(let tex):
                    Math(tex)
                        .mathFont(Math.Font(name: .latinModern, size: fontSize))
                        .mathRenderingMode(.monochrome)
                        .foregroundStyle(colorScheme == .dark ? .white : .black)
                case .displayLatex(let tex):
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

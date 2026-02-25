//
//  SelectableTextView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import AppKit

/// A non-scrollable `NSTextView` subclass that reports its intrinsic size
/// based on the laid-out text, so SwiftUI can size it correctly.
final class AutoSizingTextView: NSTextView {
    
    override var intrinsicContentSize: NSSize {
        guard let container = textContainer, let layoutManager = layoutManager else {
            return super.intrinsicContentSize
        }
        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        return NSSize(
            width: usedRect.width,
            height: usedRect.height + textContainerInset.height * 2
        )
    }
    
    override func didChangeText() {
        super.didChangeText()
        invalidateIntrinsicContentSize()
    }
    
    // Let the parent scroll view handle scrolling
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}

/// An `NSViewRepresentable` wrapping a read-only `NSTextView` that supports
/// native multi-line text selection and automatic height sizing.
struct SelectableTextView: NSViewRepresentable {
    
    let attributedString: NSAttributedString
    
    func makeCoordinator() -> Coordinator { Coordinator() }
    
    func makeNSView(context: Context) -> AutoSizingTextView {
        let textView = AutoSizingTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = false
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.isAutomaticLinkDetectionEnabled = false
        textView.delegate = context.coordinator
        
        textView.textStorage?.setAttributedString(attributedString)
        textView.invalidateIntrinsicContentSize()
        
        return textView
    }
    
    func updateNSView(_ textView: AutoSizingTextView, context: Context) {
        if textView.attributedString() != attributedString {
            textView.textStorage?.setAttributedString(attributedString)
            textView.invalidateIntrinsicContentSize()
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, nsView textView: AutoSizingTextView, context: Context) -> CGSize? {
        guard let container = textView.textContainer,
              let layoutManager = textView.layoutManager else { return nil }
        
        let width = proposal.width ?? 600
        container.containerSize = NSSize(width: width, height: .greatestFiniteMagnitude)
        layoutManager.ensureLayout(for: container)
        let usedRect = layoutManager.usedRect(for: container)
        return CGSize(width: width, height: usedRect.height + textView.textContainerInset.height * 2)
    }
    
    // MARK: - Coordinator
    
    final class Coordinator: NSObject, NSTextViewDelegate {
        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            guard let url = (link as? URL) ?? (link as? NSURL)?.absoluteURL else { return false }
            confirmOpen(url: url, in: textView.window)
            return true
        }
    }
}

/// Converts a markdown string to an `NSAttributedString` using the system
/// markdown parser, applying the specified font and line height.
func markdownAttributedString(_ markdown: String, font: NSFont, lineHeight: CGFloat, colorScheme: ColorScheme) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.minimumLineHeight = lineHeight
    paragraphStyle.maximumLineHeight = lineHeight
    
    let foregroundColor: NSColor = colorScheme == .dark ? .white : .black
    
    let baseAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .paragraphStyle: paragraphStyle,
        .foregroundColor: foregroundColor,
    ]
    
    // Try parsing markdown via the system AttributedString API
    if let mdAttr = try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
        let nsAttr = NSMutableAttributedString(mdAttr)
        // Apply base attributes across the full range, preserving bold/italic traits
        nsAttr.enumerateAttributes(in: NSRange(location: 0, length: nsAttr.length), options: []) { attrs, range, _ in
            var merged = baseAttributes
            // Preserve any existing font traits (bold, italic) from markdown parsing
            if let existingFont = attrs[.font] as? NSFont {
                let traits = existingFont.fontDescriptor.symbolicTraits
                var descriptor = font.fontDescriptor
                if traits.contains(.bold) {
                    descriptor = descriptor.withSymbolicTraits(.bold)
                }
                if traits.contains(.italic) {
                    descriptor = descriptor.withSymbolicTraits(.italic)
                }
                merged[.font] = NSFont(descriptor: descriptor, size: font.pointSize) ?? font
            }
            // Preserve link attributes
            if let link = attrs[.link] {
                merged[.link] = link
            }
            nsAttr.setAttributes(merged, range: range)
        }
        return nsAttr
    }
    
    // Fallback: plain attributed string
    return NSAttributedString(string: markdown, attributes: baseAttributes)
}

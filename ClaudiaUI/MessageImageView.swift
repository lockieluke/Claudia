//
//  MessageImageView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SDWebImageSwiftUI
import ClaudiaAPI

/// Displays a thumbnail image for a file attachment in a message bubble.
/// Uses SDWebImage for async loading and caching.
public struct MessageImageView: View {
    
    private let file: ClaudeFile
    private let namespace: Namespace.ID
    private let onTap: (URL, String, String) -> Void
    
    public init(file: ClaudeFile, namespace: Namespace.ID, onTap: @escaping (URL, String, String) -> Void) {
        self.file = file
        self.namespace = namespace
        self.onTap = onTap
    }
    
    private var thumbnailURL: URL? {
        guard let path = file.thumbnailUrl else { return nil }
        return URL(string: "https://claude.ai\(path)")
    }
    
    private var previewURL: URL? {
        guard let path = file.previewUrl else { return nil }
        return URL(string: "https://claude.ai\(path)")
    }
    
    public var body: some View {
        WebImage(url: thumbnailURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    ProgressView()
                        .scaleEffect(0.6)
                }
        }
        .frame(maxWidth: 200, maxHeight: 150)
        .clipped()
        .cornerRadius(8)
        .matchedGeometryEffect(id: file.uuid, in: namespace)
        .onTapGesture {
            if let url = previewURL ?? thumbnailURL {
                onTap(url, file.fileName, file.uuid)
            }
        }
        .cursor(.pointingHand)
    }
}

/// Cursor modifier for macOS
private struct CursorModifier: ViewModifier {
    let cursor: NSCursor
    
    func body(content: Content) -> some View {
        content.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.modifier(CursorModifier(cursor: cursor))
    }
}

//
//  ImageOverlayView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import AppKit
import SDWebImageSwiftUI
import SDWebImage
internal import UniformTypeIdentifiers

public struct ImageOverlayView: View {
    
    let imageURL: URL
    let fileName: String
    let imageID: String
    let namespace: Namespace.ID
    let onDismiss: () -> Void
    
    public init(imageURL: URL, fileName: String, imageID: String, namespace: Namespace.ID, onDismiss: @escaping () -> Void) {
        self.imageURL = imageURL
        self.fileName = fileName
        self.imageID = imageID
        self.namespace = namespace
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Dark backdrop — fades in independently
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 16) {
                WebImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    // Keep same shape as the final image during load
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(maxWidth: 800, maxHeight: 600)
                .cornerRadius(8)
                .shadow(radius: 20)
                .matchedGeometryEffect(id: imageID, in: namespace)
                .contextMenu {
                    Button("Copy Image") {
                        copyImage()
                    }
                    Button("Save Image...") {
                        saveImage()
                    }
                }
                
                Text(fileName)
                    .font(.sansFont(size: 13))
                    .foregroundStyle(.white.opacity(0.7))
                    .transition(.opacity)
            }
            
            // Close button top-right
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                Spacer()
            }
            .transition(.opacity)
        }
        .focusable(false)
        .onKeyPress(.escape) {
            onDismiss()
            return .handled
        }
    }
    
    private func cachedNSImage() -> NSImage? {
        if let cached = SDImageCache.shared.imageFromCache(forKey: SDWebImageManager.shared.cacheKey(for: imageURL)) {
            return cached
        }
        return nil
    }
    
    private func copyImage() {
        guard let nsImage = cachedNSImage() else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([nsImage])
    }
    
    private func saveImage() {
        guard let nsImage = cachedNSImage() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = fileName
        panel.allowedContentTypes = [.png, .jpeg]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            guard let tiffData = nsImage.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { return }
            try? pngData.write(to: url)
        }
    }
}

//
//  ConversationView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SVGView
import ClaudiaAPI

public struct ConversationView: View {
    
    @ObserveInjection private var inject
    
    private let conversation: ClaudeConversation
    private let availableModels: [String]
    private let onImageTap: (URL, String, String) -> Void
    private let imageNamespace: Namespace.ID
    
    private var messages: [ClaudeMessage] {
        conversation.chatMessages ?? []
    }
    
    public init(conversation: ClaudeConversation, models: [String], imageNamespace: Namespace.ID, onImageTap: @escaping (URL, String, String) -> Void) {
        self.conversation = conversation
        self.availableModels = models
        self.imageNamespace = imageNamespace
        self.onImageTap = onImageTap
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 50)
            
            GeometryReader { geometry in
                ScrollView(.vertical) {
                    LazyVStack(spacing: 25) {
                        ForEach(messages, id: \.uuid) { message in
                            let isLastMessage = message.uuid == messages.last?.uuid
                            MessageBubble(
                                message: message,
                                showSparkle: isLastMessage && message.sender == "assistant",
                                imageNamespace: imageNamespace,
                                onImageTap: onImageTap
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .frame(maxWidth: 800)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .frame(minHeight: geometry.size.height, alignment: .top)
                }
                .defaultScrollAnchor(.bottom)
                .transparentScrollbars()
            }
            
            MessageBox(models: availableModels, placeholder: "Reply...")
                .padding(.all.subtracting(.top), 30)
                .frame(maxWidth: 800)
                .frame(maxWidth: .infinity)
        }
        .enableInjection()
    }
}

struct MessageBubble: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    private static let displaySize = 16.0
    private static let displayLineHeight = 24.0
    
    /// Cached SVG string — parsed once from the asset catalog.
    private static let sparkleSVG: String = {
        String(data: NSDataAsset(name: "Claude", bundle: .main)!.data, encoding: .utf8)!
    }()
    
    let message: ClaudeMessage
    let showSparkle: Bool
    let imageNamespace: Namespace.ID
    let onImageTap: (URL, String, String) -> Void
    
    private var isHuman: Bool {
        message.sender == "human"
    }
    
    private var displayText: String {
        // Concatenate all text-type content blocks (skips tool_use, tool_result, etc.)
        let textParts = message.content.compactMap { $0.type == "text" ? $0.text : nil }
        let joined = textParts.joined(separator: "\n\n")
        return joined.isEmpty ? message.text : joined
    }
    
    private var hasImages: Bool {
        !message.imageFiles.isEmpty
    }
    
    var body: some View {
        HStack {
            if isHuman {
                Spacer()
            }
            
            VStack(alignment: isHuman ? .trailing : .leading, spacing: 10) {
                // Image attachments (shown above text)
                if hasImages {
                    HStack(spacing: 8) {
                        ForEach(message.imageFiles, id: \.uuid) { file in
                            MessageImageView(file: file, namespace: imageNamespace, onTap: onImageTap)
                        }
                    }
                }
                
                if isHuman {
                    Text(displayText)
                        .font(.sansFont(size: Self.displaySize))
                        .lineHeight(Self.displayLineHeight, fontSize: Self.displaySize)
                        .textSelection(.enabled)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(hex: "#141412") : Color(hex: "EFEFEE"))
                        }
                } else {
                    MarkdownLatexView(displayText, fontSize: Self.displaySize)
                }
                
                if showSparkle {
                    SVGView(string: Self.sparkleSVG)
                        .frame(width: 20, height: 20)
                        .padding(.vertical)
                }
            }
            .frame(maxWidth: 600, alignment: isHuman ? .trailing : .leading)
            
            if !isHuman {
                Spacer()
            }
        }
        .enableInjection()
    }
}

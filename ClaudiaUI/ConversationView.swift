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
    
    private var messages: [ClaudeMessage] {
        conversation.chatMessages ?? []
    }
    
    public init(conversation: ClaudeConversation, models: [String]) {
        self.conversation = conversation
        self.availableModels = models
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 50)
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 25) {
                    ForEach(messages, id: \.uuid) { message in
                        let isLastMessage = message.uuid == messages.last?.uuid
                        MessageBubble(message: message, showSparkle: isLastMessage && message.sender == "assistant")
                            .equatable()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            .transparentScrollbars()
            
            MessageBox(models: availableModels, placeholder: "Reply...")
        }
        .frame(maxWidth: 700)
        .enableInjection()
    }
}

struct MessageBubble: View, Equatable {
    
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
    
    static func == (lhs: MessageBubble, rhs: MessageBubble) -> Bool {
        lhs.message.uuid == rhs.message.uuid && lhs.showSparkle == rhs.showSparkle
    }
    
    private var isHuman: Bool {
        message.sender == "human"
    }
    
    private var displayText: String {
        message.content.first?.text ?? message.text
    }
    
    var body: some View {
        HStack {
            if isHuman {
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
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

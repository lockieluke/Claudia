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
                    ForEach(Array(messages.enumerated()), id: \.element.uuid) { index, message in
                        let isLastMessage = index == messages.count - 1
                        MessageBubble(message: message, showSparkle: isLastMessage && message.sender == "assistant")
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

struct MessageBubble: View {
    
    @ObserveInjection private var inject
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let displaySize = 15.0
    private let displayLineSpacing = 10.0
    
    let message: ClaudeMessage
    let showSparkle: Bool
    
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
                        .font(.sansFont(size: displaySize))
                        .lineSpacing(displayLineSpacing)
                        .textSelection(.enabled)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 10)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(colorScheme == .dark ? Color(hex: "#141412") : Color(hex: "EFEFEE"))
                        }
                } else {
                    Text(displayText)
                        .font(.serifFont(size: displaySize))
                        .lineSpacing(displayLineSpacing)
                        .textSelection(.enabled)
                }
                
                if showSparkle {
                    SVGView(string: String(data: NSDataAsset(name: "Claude", bundle: .main)!.data, encoding: .utf8)!)
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

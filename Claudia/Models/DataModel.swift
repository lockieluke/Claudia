//
//  DataModel.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import Combine
import Foundation
import ClaudiaAPI

struct ImageOverlayState {
    let imageURL: URL
    let fileName: String
    let imageID: String
}

class DataModel: ObservableObject {
    
    @Published var conversations: [ClaudeConversation] = []
    @Published var user: ClaudeAccount?
    @Published var activeConversation: ClaudeConversation?
    @Published var imageOverlay: ImageOverlayState?
    
    @Published var isLoadingMoreConversations = false
    var hasMoreConversations = true
    private let conversationPageSize = 30
    
    var conversationCache: [String: ClaudeConversation] = [:]
    
    func invalidateStaleCacheEntries(from freshList: [ClaudeConversation]) {
        for conversation in freshList {
            guard let cachedConversation = conversationCache[conversation.uuid] else { continue }
            guard let freshUpdatedAt = conversation.updatedAt,
                  let cachedUpdatedAt = cachedConversation.updatedAt else {
                // Can't compare — evict to be safe
                conversationCache.removeValue(forKey: conversation.uuid)
                continue
            }
            
            if freshUpdatedAt != cachedUpdatedAt {
                conversationCache.removeValue(forKey: conversation.uuid)
            }
        }
    }
    
    func invalidateCacheEntry(for conversationId: String) {
        conversationCache.removeValue(forKey: conversationId)
    }
    
}

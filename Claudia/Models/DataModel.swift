//
//  DataModel.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import Combine
import ClaudiaAPI

class DataModel: ObservableObject {
    
    @Published var conversations: [ClaudeConversation] = []
    @Published var user: ClaudeAccount?
    @Published var activeConversation: ClaudeConversation?
    
    var conversationCache: [String: ClaudeConversation] = [:]
    
    /// Invalidates cache entries whose `updatedAt` is older than the list response.
    /// Call this after fetching the conversation list.
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
    
    /// Invalidates a single conversation's cache entry.
    /// Call this after sending a message in a conversation.
    func invalidateCacheEntry(for conversationId: String) {
        conversationCache.removeValue(forKey: conversationId)
    }
    
}

//
//  ClaudeConversation.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

public struct ClaudeMessageContent: Decodable {
    public var type: String
    public var text: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case text
    }
}

public struct ClaudeMessage: Decodable {
    public var uuid: String
    public var text: String
    public var content: [ClaudeMessageContent]
    public var sender: String
    public var index: Int
    public var createdAt: String
    public var updatedAt: String
    public var parentMessageUuid: String
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case text
        case content
        case sender
        case index
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentMessageUuid = "parent_message_uuid"
    }
}

public struct ClaudeConversation: Decodable {
    public var name: String
    public var uuid: String
    
    // Detail fields (only present when fetching individual conversation)
    public var model: String?
    public var createdAt: String?
    public var updatedAt: String?
    public var isStarred: Bool?
    public var currentLeafMessageUuid: String?
    public var chatMessages: [ClaudeMessage]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case uuid
        case model
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isStarred = "is_starred"
        case currentLeafMessageUuid = "current_leaf_message_uuid"
        case chatMessages = "chat_messages"
    }
}

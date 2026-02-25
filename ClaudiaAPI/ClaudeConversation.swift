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

public struct ClaudeFileAsset: Decodable {
    public var url: String
    public var fileVariant: String
    public var primaryColor: String?
    public var imageWidth: Int?
    public var imageHeight: Int?
    
    enum CodingKeys: String, CodingKey {
        case url
        case fileVariant = "file_variant"
        case primaryColor = "primary_color"
        case imageWidth = "image_width"
        case imageHeight = "image_height"
    }
}

public struct ClaudeFile: Decodable {
    public var fileKind: String
    public var fileUuid: String
    public var fileName: String
    public var createdAt: String
    public var thumbnailUrl: String?
    public var previewUrl: String?
    public var thumbnailAsset: ClaudeFileAsset?
    public var previewAsset: ClaudeFileAsset?
    public var uuid: String
    
    enum CodingKeys: String, CodingKey {
        case fileKind = "file_kind"
        case fileUuid = "file_uuid"
        case fileName = "file_name"
        case createdAt = "created_at"
        case thumbnailUrl = "thumbnail_url"
        case previewUrl = "preview_url"
        case thumbnailAsset = "thumbnail_asset"
        case previewAsset = "preview_asset"
        case uuid
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
    public var files: [ClaudeFile]?
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case text
        case content
        case sender
        case index
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case parentMessageUuid = "parent_message_uuid"
        case files = "files_v2"
    }
    
    /// Returns only image file attachments.
    public var imageFiles: [ClaudeFile] {
        (files ?? []).filter { $0.fileKind == "image" }
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

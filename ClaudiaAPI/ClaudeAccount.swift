//
//  ClaudeAccount.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

internal import KeyedCodable

public struct ClaudeAccount: Decodable {
    public var fullName: String
    public var displayName: String
    public var emailAddress: String
    public var uuid: String
    
    enum CodingKeys: String, KeyedKey {
        case fullName = "full_name"
        case displayName = "display_name"
        case emailAddress = "email_address"
        case uuid
    }
}

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
    
}

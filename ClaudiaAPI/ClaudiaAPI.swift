//
//  ClaudiaAPI.swift
//  ClaudiaAPI
//
//  Created by Sherlock LUK on 21/02/2026.
//

import Foundation
import Combine
import SwiftUI
internal import Alamofire
internal import SwiftyUtils

public class API: ObservableObject {
   
    private static let ClaudeAF = Session(configuration: URLSessionConfiguration.default.then { configuration in
        configuration.httpAdditionalHeaders = [
            "anthropic-client-app": "com.anthropic.claudefordesktop",
            "anthropic-client-os-platform": "darwin",
            "anthropic-client-os-version": "\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.minorVersion).\(ProcessInfo.processInfo.operatingSystemVersion.patchVersion)",
            "anthropic-client-platform": "desktop_app",
            "anthropic-client-version": APIConstants.desktopAppVersion,
            "anthropic-desktop-topbar": 1,
            "Priority": "u=1, i",
            "User-Agent": APIConstants.desktopAppUA
        ]
    })
    private static let BASE_URL = "https://claude.ai/api"
    
    @Published public var organisationId: String? = nil
    
    public init() {
        
    }
    
    static func request<T: Decodable>(_ endpoint: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        let url = "\(BASE_URL)\(endpoint)"
        
        return try await withCheckedThrowingContinuation { continuation in
            ClaudeAF.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let value):
                        continuation.resume(returning: value)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
    
    static func orgRequest<T: Decodable>(_ endpoint: String, _ orgId: String, method: HTTPMethod = .get, parameters: Parameters? = nil, headers: HTTPHeaders? = nil) async throws -> T {
        try await self.request("/organizations/\(orgId)/\(endpoint)", method: method, parameters: parameters, headers: headers)
    }
    
    public func getAccount() async throws -> ClaudeAccount {
        try await API.request("/account")
    }
    
    public func getConversations(starred: Bool = false, limit: Int = 30, consistency: String = "strong") async throws -> [ClaudeConversation] {
        try await API.orgRequest("chat_conversations?starred=\(starred)&limit=\(limit)&consistency=\(consistency)", self.organisationId ?? "")
    }
    
}

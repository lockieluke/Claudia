//
//  ClaudiaAPI.swift
//  ClaudiaAPI
//
//  Created by Sherlock LUK on 21/02/2026.
//

import Foundation
internal import Alamofire
internal import SwiftyUtils

public struct API {
   
    private static let ClaudeAF = Session(configuration: URLSessionConfiguration.default.then { configuration in
        // TODO: Configure Claude Desktop headers
    })
    private static let BASE_URL = "https://claude.ai/api"
    
    private var organisationId: String?
    
    init() {
        
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
        try await self.request("/organization/\(orgId)/\(endpoint)", method: method, parameters: parameters, headers: headers)
    }
    
    func getConversations(starred: Bool = false, limit: Int = 30, consistency: String = "strong") {
        
    }
    
}

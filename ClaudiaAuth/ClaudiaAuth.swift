//
//  ClaudiaAuth.swift
//  ClaudiaAuth
//
//  Created by Sherlock LUK on 21/02/2026.
//

import Foundation
internal import Alamofire
internal import Defaults
import ClaudiaAPI
import AppKit
import WebKit
internal import SwiftyUtils
internal import SwiftyJSON
import os

private let logger = Logger(subsystem: "me.lockie.Claudia.Auth", category: "ClaudiaAuth")

public struct Auth {
    
    private static var wkAuthUiDelegate: WKAuthUIDelegate?
    private static var wkAuthNavigationDelegate: WKAuthNavigationDelegate?
    
    class WKAuthUIDelegate: NSObject, WKUIDelegate {
        
        func webViewDidClose(_ webView: WKWebView) {
            webView.stopLoading()
            webView.removeFromSuperview()
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                let newWebView = WKWebView(frame: webView.bounds, configuration: configuration).then {
                    $0.uiDelegate = webView.uiDelegate
                    $0.navigationDelegate = webView.navigationDelegate
                    $0.autoresizingMask = [.width, .height]
                    $0.customUserAgent = webView.customUserAgent
                }
                
                webView.addSubview(newWebView)
                
                return newWebView
            }
            
            return nil
        }
        
    }
    
    class WKAuthNavigationDelegate: NSObject, WKNavigationDelegate {
        
        private let onAuthCodeReceived: (String) -> Void
        
        init(_ onAuthCodeReceived: @escaping (String) -> Void = { _ in }) {
            self.onAuthCodeReceived = onAuthCodeReceived
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction) async -> WKNavigationActionPolicy {
            let url = navigationAction.request.url?.absoluteString ?? ""
            if url.hasPrefix("claude://") {
                if let code = URLComponents(string: url)?.queryItems?.first(where: { $0.name == "code" })?.value {
                    self.onAuthCodeReceived(code)
                }
                return .cancel
            }
            return .allow
        }
        
    }
    
    @MainActor
    public static func startGoogleAuthFlow() async -> String {
        // https://claude.ai/login/app-google-auth?open_in_browser=1&selectAccount=1
        // -> claude://login/google-auth?code=
        return await withCheckedContinuation { continuation in
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                                  styleMask: [.titled, .closable, .miniaturizable],
                                  backing: .buffered,
                                  defer: false).then {
                $0.center()
                $0.isReleasedWhenClosed = false
                $0.title = "Sign In to Claude"
            }
            
            self.wkAuthUiDelegate = WKAuthUIDelegate()
            self.wkAuthNavigationDelegate = WKAuthNavigationDelegate({ code in
                window.close()
                logger.info("Received auth code: \(code, privacy: .private(mask: .hash))")
                continuation.resume(returning: code)
            })
            
            let webView = WKWebView(frame: window.contentView!.bounds, configuration: WKWebViewConfiguration().then {
                $0.preferences.setValue(true, forKey: "developerExtrasEnabled")
                $0.preferences.javaScriptCanOpenWindowsAutomatically = true
            }).then {
                $0.uiDelegate = self.wkAuthUiDelegate
                $0.navigationDelegate = self.wkAuthNavigationDelegate
                $0.autoresizingMask = [.width, .height]
                $0.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_7_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15"
                $0.load(URLRequest(url: URL(string: "https://claude.ai/login/app-google-auth?open_in_browser=1&selectAccount=1")!))
            }
            window.contentView?.addSubview(webView)
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    public static func resolveSessionKeyFromGoogleAuth(code: String) async {
        struct VerifyGoogleParam: Encodable {
            let code: String
            let locale: String = "en-US"
            let source: String = "claude"
        }
        
        let response = await AF.request("https://claude.ai/api/auth/verify_google", method: .post, parameters: VerifyGoogleParam(code: code), encoder: JSONParameterEncoder.default, headers: [
            "anthropic-client-platform": "desktop_app",
            "anthropic-client-version": "1.0.0",
            "User-Agent": APIConstants.desktopAppUA,
            "anthropic-device-id": UUID().uuidString.lowercased()
        ])
            .cacheResponse(using: .doNotCache)
            .validate()
            .serializingData()
            .response
        
        if let data = response.data, let json = try? JSON(data: data) {
            let account = json["account"]
            if let uuid = account["uuid"].string, let email = account["email_address"].string {
                logger.info("Resolved account: \(email) (\(uuid))")
                
                if let activeMembership = account["memberships"].arrayValue.first(where: { $0["organization"]["capabilities"].arrayValue.contains("chat") }) {
                    let activeOrganisation = activeMembership["organization"]
                    if let orgId = activeOrganisation["uuid"].string {
                        logger.info("Resolved active organization: \(orgId)")
                        Defaults[Defaults.Key("lastOrgId")] = orgId
                    }
                }
                
                if let headers = response.response?.allHeaderFields as? [String: String],
                   let url = response.response?.url {
                    let cookies = HTTPCookie.cookies(withResponseHeaderFields: headers, for: url)
                    for cookie in cookies {
                        if cookie.name == "sessionKey" {
                            logger.info("Resolved session cookie: \(cookie.value, privacy: .private(mask: .hash))")
                            return
                        }
                    }
                }
            }
        }
    }
    
    public static func resolveExistingSession() async -> Bool {
        guard let claudeURL = URL(string: "https://claude.ai") else { return false }
        
        let cookies = HTTPCookieStorage.shared.cookies(for: claudeURL) ?? []
        if let sessionCookie = cookies.first(where: { $0.name == "sessionKey" }), sessionCookie.expiresDate ?? Date() > Date() {
            logger.info("Found existing session cookie: \(sessionCookie.value, privacy: .private(mask: .hash))")
            return true
        }
        
        logger.info("No existing session cookie found")
        return false
    }
    
}

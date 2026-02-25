//
//  NewChatView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SVGView

public struct NewChatView<Content: View>: View {
    
    @ObserveInjection private var inject
    
    private let content: Content
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        case 17..<22:
            return "Good evening"
        default:
            return "Hello"
        }
    }
    
    private let name: String?
    
    public init(name: String?, @ViewBuilder content: () -> Content) {
        self.name = name
        self.content = content()
    }
    
    public var body: some View {
        VStack {
            HStack(spacing: 15) {
                SVGView(string: String(data: NSDataAsset(name: "Claude", bundle: .main)!.data, encoding: .utf8)!)
                    .frame(width: 30, height: 30)
                if let name = name {
                    Text("\(greeting), \(name)")
                        .font(.serifFont(size: 30))
                        .transition(.slide.combined(with: .opacity))
                }
            }
            .animation(.spring, value: name)
            
            content
        }
        .frame(maxWidth: 700)
        .enableInjection()
    }
}

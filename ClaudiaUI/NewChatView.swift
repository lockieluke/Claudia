//
//  NewChatView.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import SVGView

public struct NewChatView: View {
    
    @ObserveInjection private var inject
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 5..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<22:
            return "Good Evening"
        default:
            return "Hello"
        }
    }
    
    private let name: String?
    
    public init(name: String?) {
        self.name = name
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
        }
        .enableInjection()
    }
}

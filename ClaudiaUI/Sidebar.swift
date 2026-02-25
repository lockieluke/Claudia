//
//  Sidebar.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import SwiftUI

public struct Sidebar<Content: View>: View {
    
    @ObserveInjection var inject
    
    private let content: Content
    
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 40)
            content
        }
        .frame(width: 280)
        .background(.gray.opacity(0.1))
        .overlay(alignment: .trailing) {
            Rectangle()
                .frame(width: 1)
                .frame(maxHeight: .infinity)
                .foregroundStyle(.gray.opacity(0.3))
        }
        .enableInjection()
    }
}

//
//  ConversationRow.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI

public struct ConversationRow: View {
    
    @ObserveInjection var inject
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    private let label: String
    private let isActive: Bool
    private var onPress: (() -> Void)?
    private var onHoverStart: (() -> Void)?
    
    public init(_ label: String, isActive: Bool = false, onHoverStart: (() -> Void)? = nil, onPress: (() -> Void)? = nil) {
        self.label = label
        self.isActive = isActive
        self.onHoverStart = onHoverStart
        self.onPress = onPress
    }
    
    public var body: some View {
        HStack {
            Text(label)
                .font(.sansFont(size: 13))
                .tracking(0.2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .onHover { isHovering in
            self.isHovering = isHovering
            if isHovering {
                self.onHoverStart?()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    self.isClicking = true
                }
                .onEnded { _ in
                    self.isClicking = false
                    self.onPress?()
                }
        )
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.25))
            } else if isHovering {
                RoundedRectangle(cornerRadius: 4)
                    .fill(isClicking ? .gray.opacity(0.3) :.gray.opacity(0.2))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .padding(.horizontal)
        .enableInjection()
    }
    
}

#Preview {
    ConversationRow("New Chat")
}

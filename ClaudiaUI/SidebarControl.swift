//
//  SidebarControl.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import SwiftUI

public struct SidebarControl: View {
    
    @ObserveInjection var inject
    
    @State private var isHovering = false
    @State private var isClicking = false
    
    private let label: String
    private let icon: SFSymbol
    private var onPress: (() -> Void)?
    
    public init(_ label: String, icon: SFSymbol, onPress: (() -> Void)? = nil) {
        self.label = label
        self.icon = icon
        self.onPress = onPress
    }
    
    public var body: some View {
        HStack {
            Image(systemSymbol: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 12, height: 12)
                .padding(.horizontal, 5)
                .padding(.leading, 5)
            Text(label)
                .font(.sansFont(size: 13))
                .tracking(0.3)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: 30)
        .onHover { isHovering in
            self.isHovering = isHovering
        }
        .onTapGesture {
            self.onPress?()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    self.isClicking = true
                }
                .onEnded { _ in
                    self.isClicking = false
                }
        )
        .background {
            if isHovering {
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
    SidebarControl("New Chat", icon: .plus)
}

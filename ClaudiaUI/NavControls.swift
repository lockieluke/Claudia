//
//  NavControls.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import SwiftUI

public struct NavControls: View {
    
    @ObserveInjection var inject
    
    @State private var isHovering = false
    
    private let systemSymbol: SFSymbol
    private var onPress: (() -> Void)?
    
    init(systemSymbol: SFSymbol, onPress: (() -> Void)? = nil) {
        self.systemSymbol = systemSymbol
        self.onPress = onPress
    }
    
    public var body: some View {
        VStack {
            Button {
                self.onPress?()
            } label: {
                Image(systemSymbol: systemSymbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
            }
            .onHover { hovering in
                self.isHovering = hovering
            }
            .focusable(false)
            .padding(5)
            .buttonStyle(.plain)
            .background {
                if isHovering {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.gray.opacity(0.2))
                }
            }
        }
        .enableInjection()
    }
}

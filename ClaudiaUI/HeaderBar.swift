//
//  HeaderBar.swift
//  Claudia
//
//  Created by Sherlock LUK on 22/02/2026.
//

import SwiftUI

public struct HeaderBar: View {
    
    @ObserveInjection var inject
    
    @Binding private var inFullscreen: Bool
    
    public enum NavAction {
        case toggleSidebar
    }
    
    private let onNavAction: ((_ navAction: NavAction) -> Void)?
    
    public init(inFullscreen: Binding<Bool>, onNavAction: ((_ navAction: NavAction) -> Void)? = nil) {
        self.onNavAction = onNavAction
        self._inFullscreen = inFullscreen
    }
    
    public var body: some View {
        HStack {
            Spacer()
                .frame(width: inFullscreen ? 20 : 85)
            NavControls(systemSymbol: .sidebarLeading, onPress: {
                self.onNavAction?(.toggleSidebar)
            })
                .padding(.horizontal, 2)
                .help("Toggle sidebar ⌘S")
                .keyboardShortcut("s", modifiers: .command)
            Text("Claudia")
                .font(.serifFont(size: 15))
            Spacer()
        }
        .padding(.vertical)
        .enableInjection()
    }
}

#Preview {
    HeaderBar(inFullscreen: .constant(false))
}

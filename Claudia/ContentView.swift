//
//  ContentView.swift
//  Claudia
//
//  Created by Sherlock LUK on 21/02/2026.
//

import SwiftUI
import ClaudiaAuth
import ClaudiaUI
import Defaults

struct ContentView: View {
    
    @EnvironmentObject private var navigationModel: NavigationModel
    
    @Default(.sidebarOpened) private var sidebarOpened
    @State private var showSidebar = Defaults[.sidebarOpened]
    
    @ObserveInjection var inject
    
    var body: some View {
        HStack {
            if showSidebar {
                Sidebar {
                    VStack(spacing: 5) {
                        SidebarControl("New Chat", icon: .plus)
                        SidebarControl("Search", icon: .magnifyingglass)
                    }
                    .padding(.vertical)
                }
                .transition(.move(edge: .leading))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay {
            VStack {
                HeaderBar(inFullscreen: $navigationModel.isFullscreen) { navAction in
                    switch navAction {
                    case .toggleSidebar:
                        self.sidebarOpened.toggle()
                        withAnimation(.interactiveSpring) {
                            self.showSidebar.toggle()
                        }
                    }
                }
                Spacer()
            }
        }
        .task {
            if !(await Auth.resolveExistingSession()) {
                let code = await Auth.startGoogleAuthFlow()
                await Auth.resolveSessionKeyFromGoogleAuth(code: code)
            }
        }
        .ignoresSafeArea()
        .enableInjection()
    }
}

#Preview {
    ContentView()
}

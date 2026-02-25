//
//  ContentView.swift
//  Claudia
//
//  Created by Sherlock LUK on 21/02/2026.
//

import SwiftUI
import ClaudiaAPI
import ClaudiaAuth
import ClaudiaUI
import Defaults

struct ContentView: View {
    
    @EnvironmentObject private var dataModel: DataModel
    @EnvironmentObject private var navigationModel: NavigationModel
    @EnvironmentObject private var api: API
    
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
                        
                        Divider()
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        
                        
                        ScrollView(.vertical) {
                            Text("Recents")
                                .font(.sansFont(size: 11))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 23)
                                .foregroundStyle(.gray)
                            
                            LazyVStack {
                                ForEach(dataModel.conversations, id: \.uuid) { conversation in
                                    ConversationRow(conversation.name)
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    .padding(.vertical)
                }
                .transition(.move(edge: .leading))
            }
            
            NewChatView(name: dataModel.user?.displayName)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            self.api.organisationId = Defaults[.lastOrganisationId]
            
            do {
                async let accountProc = try await self.api.getAccount()
                async let conversationsProc = try await self.api.getConversations()
                
                let (account, conversations) = try await (accountProc, conversationsProc)
                self.dataModel.user = account
                self.dataModel.conversations = conversations
            } catch {
                print("Failed to fetch initial data: \(error.localizedDescription)")
            }
        }
        .ignoresSafeArea()
        .enableInjection()
    }
}

#Preview {
    ContentView()
}

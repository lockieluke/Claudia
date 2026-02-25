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
                        SidebarControl("New Chat", icon: .plus) {
                            self.dataModel.activeConversation = nil
                        }
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
                                    ConversationRow(conversation.name) {
                                        Task {
                                            do {
                                                let fullConversation = try await self.api.getConversation(conversation.uuid)
                                                self.dataModel.activeConversation = fullConversation
                                            } catch {
                                                print("Failed to fetch conversation: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    .padding(.vertical)
                }
                .transition(.move(edge: .leading))
            }
            
            if let activeConversation = dataModel.activeConversation {
                ConversationView(conversation: activeConversation, models: ["Sonnet 4.6", "Haiku 4.6", "Opus 4.6"])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                NewChatView(name: dataModel.user?.displayName) {
                    MessageBox(models: ["Sonnet 4.6", "Haiku 4.6", "Opus 4.6"])
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
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
            
            guard self.api.organisationId != nil else {
                print("Failed to fetch initial data: missing organisation ID")
                return
            }
            
            do {
                async let accountProc = self.api.getAccount()
                async let conversationsProc = self.api.getConversations()
                
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

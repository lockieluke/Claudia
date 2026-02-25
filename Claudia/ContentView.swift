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
    
    @Namespace private var imageNamespace
    
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
                                    ConversationRow(
                                        conversation.name,
                                        isActive: dataModel.activeConversation?.uuid == conversation.uuid,
                                        onHoverStart: {
                                            guard dataModel.conversationCache[conversation.uuid] == nil else { return }
                                            Task {
                                                do {
                                                    let fullConversation = try await self.api.getConversation(conversation.uuid)
                                                    self.dataModel.conversationCache[conversation.uuid] = fullConversation
                                                } catch {
                                                    print("Failed to prefetch conversation: \(error.localizedDescription)")
                                                }
                                            }
                                        }, onPress: {
                                            if let cached = dataModel.conversationCache[conversation.uuid] {
                                                self.dataModel.activeConversation = cached
                                            } else {
                                                Task {
                                                    do {
                                                        let fullConversation = try await self.api.getConversation(conversation.uuid)
                                                        self.dataModel.conversationCache[conversation.uuid] = fullConversation
                                                        self.dataModel.activeConversation = fullConversation
                                                    } catch {
                                                        print("Failed to fetch conversation: \(error.localizedDescription)")
                                                    }
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .transparentScrollbars()
                    }
                    .padding(.top)
                }
                .transition(.move(edge: .leading))
            }
            
            if let activeConversation = dataModel.activeConversation {
                ConversationView(conversation: activeConversation, models: ["Sonnet 4.6", "Haiku 4.6", "Opus 4.6"], imageNamespace: imageNamespace) { imageURL, fileName, imageID in
                    withAnimation(.interactiveSpring) {
                        dataModel.imageOverlay = ImageOverlayState(imageURL: imageURL, fileName: fileName, imageID: imageID)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .topLeading) {
                    Text(activeConversation.name)
                        .font(.sansFont(size: 15))
                        .tracking(0.1)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 19)
                        .padding(.leading, showSidebar ? 20 : (navigationModel.isFullscreen ? 130 : 200))
                        .allowsHitTesting(false)
                }
            } else {
                NewChatView(name: dataModel.user?.displayName) {
                    MessageBox(models: ["Sonnet 4.6", "Haiku 4.6", "Opus 4.6"])
                        .padding(30)
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
        .overlay {
            if let overlayState = dataModel.imageOverlay {
                ImageOverlayView(
                    imageURL: overlayState.imageURL,
                    fileName: overlayState.fileName,
                    imageID: overlayState.imageID,
                    namespace: imageNamespace
                ) {
                    withAnimation(.interactiveSpring) {
                        dataModel.imageOverlay = nil
                    }
                }
                .zIndex(100)
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
                self.dataModel.invalidateStaleCacheEntries(from: conversations)
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

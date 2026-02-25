//
//  ClaudiaApp.swift
//  Claudia
//
//  Created by Sherlock LUK on 21/02/2026.
//

import SwiftUI
import ClaudiaUI
import ClaudiaAPI
@_spi(Advanced) import SwiftUIIntrospect

class WindowObserver: NSObject, NSWindowDelegate {
    
    enum ChangeState {
        case enterFullScreen
        case exitFullScreen
    }
    
    private var onChange: (ChangeState) -> Void
    
    init(onChange: @escaping (ChangeState) -> Void) {
        self.onChange = onChange
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        self.onChange(.enterFullScreen)
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        self.onChange(.exitFullScreen)
    }
}

@main
struct ClaudiaApp: App {
    
    @ObserveInjection private var inject
    
    @StateObject private var navigationModel = NavigationModel()
    @StateObject private var api = API()
    @StateObject private var dataModel = DataModel()
    
    private func onResize(nsWindow: NSWindow? = nil) {
        nsWindow?.moveTrafficLights(to: NSPoint(x: 20, y: 17))
    }
    
    var body: some Scene {
        WindowGroup {
            var nsWindow: NSWindow?
            
            ContentView()
                .introspect(.window, on: .macOS(.v10_15...)) { window in
                    guard objc_getAssociatedObject(window, "windowObserver") == nil else { return }
                    
                    let observer = WindowObserver { state in
                        withAnimation(.interactiveSpring) {
                            switch state {
                            case .enterFullScreen:
                                navigationModel.isFullscreen = true
                            case .exitFullScreen:
                                navigationModel.isFullscreen = false
                            }
                        }
                    }
                    window.delegate = observer
                    objc_setAssociatedObject(window, "windowObserver", observer, .OBJC_ASSOCIATION_RETAIN)
                    
                    nsWindow = window
                    self.onResize(nsWindow: window)
                }
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { newSize in
                    self.onResize(nsWindow: nsWindow)
                }
                .environmentObject(navigationModel)
                .environmentObject(api)
                .environmentObject(dataModel)
                .enableInjection()
            
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}

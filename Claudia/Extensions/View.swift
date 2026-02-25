//
//  View.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import SwiftUI
import SwiftUIIntrospect

// Taken from https://github.com/lockieluke/cider-swiftui/blob/e87ba9c48b90aa172728d5746ad06e62b6d48539/Cider/Views/ViewModifiers/TransparentScrollbarsModifier.swift
private struct TransparentScrollbarsModifier: ViewModifier {
    
    var enabled: Bool
    
    func body(content: Content) -> some View {
#if canImport(AppKit)
        content
            .introspect(.scrollView, on: .macOS(.v10_15, .v11, .v12, .v13, .v14)) { scrollView in
                scrollView.autohidesScrollers = true
                scrollView.scrollerStyle = .overlay
            }
#else
        return content
#endif
    }
    
}

extension View {
    
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    func erasedToAnyView() -> AnyView {
        AnyView(self)
    }
    
    func transparentScrollbars(_ enabled: Bool = true) -> some View {
        self.modifier(TransparentScrollbarsModifier(enabled: enabled))
    }
    
}

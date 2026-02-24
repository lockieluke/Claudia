//
//  View.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import SwiftUI

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
    
}

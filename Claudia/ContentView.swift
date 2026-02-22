//
//  ContentView.swift
//  Claudia
//
//  Created by Sherlock LUK on 21/02/2026.
//

import SwiftUI
import ClaudiaAuth
@_exported import Inject

struct ContentView: View {
    @ObserveInjection var inject
    
    var body: some View {
        VStack {
        }
        .task {
            if !(await Auth.resolveExistingSession()) {
                let code = await Auth.startGoogleAuthFlow()
                await Auth.resolveSessionKeyFromGoogleAuth(code: code)
            }
        }
        .padding()
        .enableInjection()
    }
}

#Preview {
    ContentView()
}

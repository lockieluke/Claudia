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
            let code = await ClaudiaAuth.startGoogleAuthFlow()
            await ClaudiaAuth.resolveSessionKeyFromGoogleAuth(code: code)
        }
        .padding()
        .enableInjection()
    }
}

#Preview {
    ContentView()
}

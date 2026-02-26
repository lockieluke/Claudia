//
//  LinkConfirmation.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import AppKit
import SwiftUI

func confirmOpen(url: URL, in window: NSWindow?) {
    let alert = NSAlert()
    alert.messageText = "Open external link?"
    alert.informativeText = url.absoluteString
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Open")
    alert.addButton(withTitle: "Cancel")
    
    let run: (NSApplication.ModalResponse) -> Void = { response in
        if response == .alertFirstButtonReturn {
            NSWorkspace.shared.open(url)
        }
    }
    
    if let window {
        alert.beginSheetModal(for: window, completionHandler: run)
    } else {
        run(alert.runModal())
    }
}

struct ConfirmingOpenURLAction: ViewModifier {
    func body(content: Content) -> some View {
        content.environment(\.openURL, OpenURLAction { url in
            confirmOpen(url: url, in: NSApp.keyWindow)
            return .handled
        })
    }
}

extension View {
    func confirmExternalLinks() -> some View {
        modifier(ConfirmingOpenURLAction())
    }
}

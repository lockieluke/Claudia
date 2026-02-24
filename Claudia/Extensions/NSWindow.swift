//
//  NSWindow.swift
//  Claudia
//
//  Created by Sherlock LUK on 24/02/2026.
//

import AppKit

extension NSWindow {
    func moveTrafficLights(to point: NSPoint) {
        let buttons: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
        
        for (index, buttonType) in buttons.enumerated() {
            guard let button = standardWindowButton(buttonType) else { continue }
            button.setFrameOrigin(NSPoint(
                x: point.x + CGFloat(index) * 20,
                y: -point.y + button.frame.height / 2
            ))
        }
    }
}

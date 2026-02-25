//
//  WindowDragArea.swift
//  Claudia
//
//  Created by Sherlock LUK on 25/02/2026.
//

import SwiftUI
import AppKit
import Dynamic

struct WindowDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> DragView { DragView() }
    func updateNSView(_ nsView: DragView, context: Context) {}

    final class DragView: NSView {
        override var mouseDownCanMoveWindow: Bool { true }

        override func mouseDown(with event: NSEvent) {
            if event.clickCount == 2 {
                Dynamic(window)._zoomFill(nil)
            } else {
                window?.performDrag(with: event)
            }
        }
    }
}

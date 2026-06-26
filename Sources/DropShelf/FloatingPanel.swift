import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless],
            backing: backing,
            defer: flag
        )
        
        // Make it floating and transparent
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false 
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        
        // Behavior: don't activate the app, and allow clicks to pass through if needed
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    override var canBecomeKey: Bool {
        return true
    }
    
    // Bypass macOS automatic window position clamping.
    // By default, NSWindow.constrainFrameRect clips the frame to visibleFrame,
    // which pushes the window below the Menu Bar / Notch area.
    // Returning the unconstrained rect for topCenter allows flush alignment.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        if AppSettings.shared.position == .topCenter {
            return frameRect
        }
        return super.constrainFrameRect(frameRect, to: screen)
    }
}

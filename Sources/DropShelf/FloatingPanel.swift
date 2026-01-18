import SwiftUI
import AppKit

class FloatingPanel: NSPanel {
    init(contentRect: NSRect, backing: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView],
            backing: backing,
            defer: flag
        )
        
        // Make it floating and transparent
        self.isFloatingPanel = true
        self.level = .floating
        self.hidesOnDeactivate = false // CRITICAL: Stop auto-hiding on drag-out
        self.isMovableByWindowBackground = false 
        self.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
        self.hasShadow = true
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.standardWindowButton(.closeButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
        self.standardWindowButton(.zoomButton)?.isHidden = true
        
        // Behavior: don't activate the app, and allow clicks to pass through if needed (though we want drops)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    }
    
    override var canBecomeKey: Bool {
        return true
    }
}

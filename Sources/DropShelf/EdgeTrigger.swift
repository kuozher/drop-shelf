import SwiftUI
import AppKit

class EdgeTrigger: ObservableObject {
    private var monitor: Any?
    private let threshold: CGFloat = 5.0
    
    var onEdgeTouch: (() -> Void)?
    
    init() {
        startMonitoring()
    }
    
    private var lastLocation: NSPoint = .zero
    
    func startMonitoring() {
        print("EdgeTrigger monitoring started")
        
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self else { return }
            let mouseLocation = NSEvent.mouseLocation
            
            // 1. Edge Detection (Active screen containing mouse)
            if let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) {
                let position = AppSettings.shared.position
                let screenHeight = targetScreen.frame.height
                let screenMinY = targetScreen.frame.minY
                let screenMaxY = targetScreen.frame.maxY
                
                if position == .topCenter {
                    // 1. Calculate actual top bar / notch height dynamic to the screen
                    let topBarHeight = targetScreen.frame.maxY - targetScreen.visibleFrame.maxY
                    
                    // 2. Determine top threshold based on whether user is dragging an item or just moving the mouse
                    let isDragging = event.type == .leftMouseDragged
                    let topThreshold = isDragging ? (topBarHeight + 15.0) : (topBarHeight + 3.0)
                    let isAtTopEdge = mouseLocation.y >= screenMaxY - topThreshold
                    
                    // 3. Narrow the horizontal range to center 180pt (matching physical notch width)
                    let midX = targetScreen.frame.midX
                    let triggerWidth: CGFloat = 180.0
                    let centerMinX = midX - (triggerWidth / 2)
                    let centerMaxX = midX + (triggerWidth / 2)
                    let isAtHorizontalCenter = mouseLocation.x >= centerMinX && mouseLocation.x <= centerMaxX
                    
                    if isAtTopEdge && isAtHorizontalCenter {
                        print("Edge detected inside valid zone (\(position.rawValue)) at \(mouseLocation)")
                        self.trigger()
                    }
                } else {
                    // 1. Horizontal Check (Left vs Right)
                    var isHorizontalMatch = false
                    let isLeft = position.rawValue.contains("left")
                    
                    if isLeft {
                        if mouseLocation.x <= targetScreen.frame.minX + threshold { isHorizontalMatch = true }
                    } else {
                        if mouseLocation.x >= targetScreen.frame.maxX - threshold { isHorizontalMatch = true }
                    }
                    
                    if isHorizontalMatch {
                        // 2. Vertical Range Check (Top / Center / Bottom)
                        var validMinY: CGFloat = 0
                        var validMaxY: CGFloat = 0
                        
                        if position.rawValue.contains("Top") {
                            // Top 40%
                            validMinY = screenMaxY - (screenHeight * 0.40)
                            validMaxY = screenMaxY
                        } else if position.rawValue.contains("Bottom") {
                            // Bottom 40%
                            validMinY = screenMinY
                            validMaxY = screenMinY + (screenHeight * 0.40)
                        } else {
                            // Center 40% (Top 30% and Bottom 30% are dead zones)
                            validMinY = screenMinY + (screenHeight * 0.30)
                            validMaxY = screenMaxY - (screenHeight * 0.30)
                        }
                        
                        if mouseLocation.y >= validMinY && mouseLocation.y <= validMaxY {
                            print("Edge detected inside valid zone (\(position.rawValue)) at \(mouseLocation)")
                            self.trigger()
                        }
                    }
                }
            }
            
            self.lastLocation = mouseLocation
        }
        
        // Global monitor (for when other apps are focused)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged], handler: handler)
        
        // Local monitor (for when our panel is focused)
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged]) { event in
            handler(event)
            return event
        }
    }
    
    private func trigger() {
        DispatchQueue.main.async {
            self.onEdgeTouch?()
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

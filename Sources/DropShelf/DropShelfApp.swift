import SwiftUI
import AppKit
import Combine

@main
struct DropShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

// Custom NSHostingView that handles routing AppKit dragging destination events
class DragAwareHostingView<Content: View>: NSHostingView<Content> {
    private var isReceivingDrag = false
    
    required init(rootView: Content) {
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForDraggedTypes([.fileURL])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        isReceivingDrag = true
        return super.draggingEntered(sender)
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isReceivingDrag = false
        super.draggingExited(sender)
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isReceivingDrag = false
        super.draggingEnded(sender)
    }
    
    override func hitTest(_ point: NSPoint) -> NSView? {
        let settings = AppSettings.shared
        if settings.position == .topCenter && settings.isCollapsed {
            // Window is 180x40. Visual capsule is at top y: 12..40.
            // Bottom 12pt is transparent trigger area.
            if point.y < 12 {
                // Click-through when not receiving an active drag
                if !isReceivingDrag {
                    return nil
                }
            }
        }
        return super.hitTest(point)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    private var edgeTrigger = EdgeTrigger()
    private var isVisible = false
    private var isAnimatingWindow = false
    private var currentContentHeight: CGFloat = 150
    private var settings = AppSettings.shared
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropShelf applicationDidFinishLaunching")
        let contentView = ContentView()
            .edgesIgnoringSafeArea(.all)
        
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: currentContentHeight),
            backing: .buffered,
            defer: false
        )
        
        let hostingView = DragAwareHostingView(rootView: contentView)
        panel.contentView = hostingView
        
        // Initial setup for level and persistence
        panel.level = .floating
        panel.hidesOnDeactivate = false
        
        // Setup Combine subscriptions for setting updates
        setupCombineSubscriptions()
        
        // Show window immediately
        showWindow()
        
        edgeTrigger.onEdgeTouch = { [weak self] in
            print("Edge/Shake trigger received in AppDelegate")
            guard let self = self else { return }
            
            if self.settings.position == .topCenter {
                // If it's a top notch shelf, touching the top edge expands it
                if self.settings.isCollapsed {
                    withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                        self.settings.isCollapsed = false
                    }
                }
            } else {
                self.showWindow()
            }
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("windowHeightChanged"), object: nil, queue: .main) { [weak self] notification in
            if let height = notification.userInfo?["height"] as? CGFloat {
                self?.currentContentHeight = height
                self?.updatePosition()
            }
        }
        
        checkAccessibilityPermissions()
    }
    
    private func setupCombineSubscriptions() {
        // Observe collapsed state to trigger AppKit window resize transitions
        settings.$isCollapsed
            .receive(on: RunLoop.main)
            .sink { [weak self] isCollapsed in
                self?.handleCollapseChange(isCollapsed)
            }
            .store(in: &cancellables)
            
        // Observe screen position change to adapt window properties dynamically
        settings.$position
            .receive(on: RunLoop.main)
            .sink { [weak self] pos in
                guard let self = self else { return }
                if pos == .topCenter {
                    self.settings.isCollapsed = true
                    self.panel.backgroundColor = .clear
                    self.panel.hasShadow = false
                    self.panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.mainMenuWindow.rawValue) + 1)
                } else {
                    self.settings.isCollapsed = false
                    self.panel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.9)
                    self.panel.hasShadow = true
                    self.panel.level = .floating
                }
                self.updatePosition()
            }
            .store(in: &cancellables)
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !accessEnabled {
            print("WARNING: Accessibility permissions are REQUIRED.")
        }
    }
    
    // Multi-Monitor Screen Detection based on mouse location
    private func getTargetScreen() -> NSScreen {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        return screens.first { NSMouseInRect(mouseLocation, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first!
    }
    
    private func handleCollapseChange(_ isCollapsed: Bool) {
        guard settings.position == .topCenter else { return }
        // We no longer resize the NSWindow here! The window is permanently fixed at 348x800.
        // SwiftUI handles the internal animation.
        // We just ensure it's frontmost when expanded.
        if !isCollapsed {
            panel.orderFrontRegardless()
        }
    }
    
    func updatePosition() {
        guard isVisible, !isAnimatingWindow else { return }
        let screen = getTargetScreen()
        let windowSize = CGSize(width: 300, height: currentContentHeight)
        let targetRect = calculatePosition(for: settings.position, screen: screen, windowSize: windowSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().setFrame(targetRect, display: true)
        }
    }
    
    func showWindow() {
        if settings.position == .topCenter {
            panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelKey.mainMenuWindow.rawValue) + 1)
        } else {
            panel.level = .floating
        }
        panel.hidesOnDeactivate = false
        
        if isVisible && !isAnimatingWindow {
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        isVisible = true
        isAnimatingWindow = true
        
        let screen = getTargetScreen()
        let windowSize = CGSize(width: 300, height: currentContentHeight)
        let targetRect = calculatePosition(for: settings.position, screen: screen, windowSize: windowSize)
        
        var startRect = targetRect
        if settings.position == .topCenter {
            // For topCenter, the window is always the same fixed size, anchored at the top
            let fixedHeight: CGFloat = 800
            startRect = NSRect(x: screen.frame.midX - 174, y: screen.frame.maxY - fixedHeight, width: 348, height: fixedHeight)
        } else if settings.position.rawValue.contains("right") {
            startRect.origin.x = screen.frame.width + 20
        } else {
            startRect.origin.x = -windowSize.width - 20
        }
        
        if !panel.isVisible {
            panel.setFrame(startRect, display: true)
        }
        
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        if settings.position == .topCenter {
            isAnimatingWindow = false
        } else {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                panel.animator().setFrame(targetRect, display: true)
            } completionHandler: {
                self.isAnimatingWindow = false
            }
        }
    }
    
    @objc func hideWindow(animated: Bool = true) {
        if settings.position == .topCenter {
            // Collapse instead of ordering out
            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                settings.isCollapsed = true
            }
            return
        }
        
        guard isVisible else { return }
        isVisible = false
        isAnimatingWindow = true
        
        let screen = getTargetScreen()
        let windowSize = panel.frame.size
        
        var targetRect = calculatePosition(for: settings.position, screen: screen, windowSize: windowSize)
        if settings.position.rawValue.contains("right") {
            targetRect.origin.x = screen.frame.width + 20
        } else {
            targetRect.origin.x = -windowSize.width - 20
        }
        
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.3
                panel.animator().setFrame(targetRect, display: true)
            } completionHandler: {
                if !self.isVisible {
                    self.panel.orderOut(nil)
                }
                self.isAnimatingWindow = false
            }
        } else {
            panel.setFrame(targetRect, display: true)
            panel.orderOut(nil)
            isAnimatingWindow = false
        }
    }
    
    private func calculatePosition(for pos: ScreenPosition, screen: NSScreen, windowSize: CGSize) -> NSRect {
        let screenFrame = screen.visibleFrame
        let fullScreenFrame = screen.frame
        var x: CGFloat = 0
        var y: CGFloat = 0
        let margin: CGFloat = 20
        
        switch pos {
        case .leftTop:
            x = screenFrame.minX + margin
            y = screenFrame.maxY - windowSize.height - margin
        case .leftCenter:
            x = screenFrame.minX + margin
            y = screenFrame.midY - (windowSize.height / 2)
        case .leftBottom:
            x = screenFrame.minX + margin
            y = screenFrame.minY + margin
        case .rightTop:
            x = screenFrame.maxX - windowSize.width - margin
            y = screenFrame.maxY - windowSize.height - margin
        case .rightCenter:
            x = screenFrame.maxX - windowSize.width - margin
            y = screenFrame.midY - (windowSize.height / 2)
        case .rightBottom:
            x = screenFrame.maxX - windowSize.width - margin
            y = screenFrame.minY + margin
        case .topCenter:
            // The physical NSWindow is permanently full size.
            // SwiftUI internally moves the UI up and down.
            let expandedWidth: CGFloat = 348
            let fixedHeight: CGFloat = 800
            x = fullScreenFrame.midX - expandedWidth / 2
            y = fullScreenFrame.maxY - fixedHeight
            return NSRect(x: x, y: y, width: expandedWidth, height: fixedHeight)
        }
        
        return NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
    }
}

import SwiftUI
import AppKit

@main
struct DropShelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    private var edgeTrigger = EdgeTrigger()
    private var isVisible = false
    private var isAnimating = false
    private var currentContentHeight: CGFloat = 150
    private var settings = AppSettings.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("DropShelf applicationDidFinishLaunching")
        let contentView = ContentView()
            .edgesIgnoringSafeArea(.all)
        
        panel = FloatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: currentContentHeight),
            backing: .buffered,
            defer: false
        )
        
        panel.contentView = NSHostingView(rootView: contentView)
        
        // Initial setup for level and persistence
        panel.level = .floating
        panel.hidesOnDeactivate = false
        
        // FOR DEBUGGING: Show window immediately
        showWindow()
        
        edgeTrigger.onEdgeTouch = { [weak self] in
            print("Edge/Shake trigger received in AppDelegate")
            self?.showWindow()
        }
        
        NotificationCenter.default.addObserver(forName: UserDefaults.didChangeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.updatePosition()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("windowHeightChanged"), object: nil, queue: .main) { [weak self] notification in
            if let height = notification.userInfo?["height"] as? CGFloat {
                self?.currentContentHeight = height
                self?.updatePosition()
            }
        }
        
        checkAccessibilityPermissions()
    }
    
    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
        if !accessEnabled {
            print("WARNING: Accessibility permissions are REQUIRED.")
        }
    }
    
    func updatePosition() {
        guard isVisible, !isAnimating else { return }
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = CGSize(width: 300, height: currentContentHeight)
        let targetRect = calculatePosition(for: settings.position, screenFrame: screenFrame, windowSize: windowSize)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().setFrame(targetRect, display: true)
        }
    }
    
    func showWindow() {
        // Reinforce level and persistence every show
        panel.level = .floating
        panel.hidesOnDeactivate = false
        
        // If already showing and NOT animating, just bring to front
        if isVisible && !isAnimating {
            panel.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        isVisible = true
        isAnimating = true
        
        let screenFrame = NSScreen.main?.visibleFrame ?? .zero
        let windowSize = panel.frame.size
        let targetRect = calculatePosition(for: settings.position, screenFrame: screenFrame, windowSize: windowSize)
        
        // Ensure starting position is correct for transition
        var startRect = targetRect
        if settings.position.rawValue.contains("right") {
            startRect.origin.x = (NSScreen.main?.frame.width ?? 2000) + 20
        } else {
            startRect.origin.x = -windowSize.width - 20
        }
        
        if !panel.isVisible {
            panel.setFrame(startRect, display: true)
        }
        
        panel.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(targetRect, display: true)
        } completionHandler: {
            self.isAnimating = false
        }
    }
    
    @objc func hideWindow(animated: Bool = true) {
        guard isVisible else { return }
        isVisible = false
        isAnimating = true
        
        let screenFrame = NSScreen.main?.frame ?? .zero
        let windowSize = panel.frame.size
        
        var targetRect = calculatePosition(for: settings.position, screenFrame: screenFrame, windowSize: windowSize)
        if settings.position.rawValue.contains("right") {
            targetRect.origin.x = screenFrame.width + 20
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
                self.isAnimating = false
            }
        } else {
            panel.setFrame(targetRect, display: true)
            panel.orderOut(nil)
            isAnimating = false
        }
    }
    
    private func calculatePosition(for pos: ScreenPosition, screenFrame: NSRect, windowSize: CGSize) -> NSRect {
        var x: CGFloat = 0
        var y: CGFloat = 0
        let margin: CGFloat = 20
        
        switch pos {
        case .leftTop:
            x = margin
            y = screenFrame.maxY - windowSize.height - margin
        case .leftCenter:
            x = margin
            y = screenFrame.midY - (windowSize.height / 2)
        case .leftBottom:
            x = margin
            y = margin
        case .rightTop:
            x = screenFrame.maxX - windowSize.width - margin
            y = screenFrame.maxY - windowSize.height - margin
        case .rightCenter:
            x = screenFrame.maxX - windowSize.width - margin
            y = screenFrame.midY - (windowSize.height / 2)
        case .rightBottom:
            x = screenFrame.maxX - windowSize.width - margin
            y = margin
        }
        
        return NSRect(x: x, y: y, width: windowSize.width, height: windowSize.height)
    }
}

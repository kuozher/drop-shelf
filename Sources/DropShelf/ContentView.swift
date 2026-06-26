import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject var viewModel = FileShelfViewModel()
    @StateObject var settings = AppSettings.shared
    
    // Grid Configuration
    let columns = [
        GridItem(.fixed(80)),
        GridItem(.fixed(80)),
        GridItem(.fixed(80))
    ]
    
    // Max allowable height for the window
    let maxWindowHeight: CGFloat = 600
    
    // Notch/menu bar height for the current screen
    private var notchHeight: CGFloat {
        guard settings.position == .topCenter,
              let screen = NSScreen.main else { return 0 }
        return screen.frame.maxY - screen.visibleFrame.maxY
    }
    
    var body: some View {
        Group {
            VStack(spacing: 0) {
                if settings.position == .topCenter && settings.isCollapsed {
                    CollapsedNotchView(viewModel: viewModel, settings: settings)
                        // Ignore hover on the notch view itself because the mouse can't reach it
                } else {
                VStack(spacing: 0) {
                    
                    // Notch area spacer: fills the region behind the physical notch
                    if settings.position == .topCenter {
                        Color.black.frame(height: notchHeight)
                    }
                    
                    // ================= HEADER =================
                    HStack(spacing: 8) {
                        Text("\(viewModel.files.count) items")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(settings.position == .topCenter ? .gray : .secondary)
                        
                        if viewModel.selectedCount > 0 {
                            Text("(\(viewModel.selectedCount) selected)")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        // Settings Button
                        Button(action: { viewModel.showingSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.hoverSettings ? .blue : .gray)
                                .frame(width: 24, height: 24)
                                .background(viewModel.hoverSettings ? Color.gray.opacity(0.15) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .onHover { viewModel.hoverSettings = $0 }
                        
                        // Hide Button
                        Button(action: {
                            NSApp.sendAction(#selector(AppDelegate.hideWindow), to: nil, from: nil)
                        }) {
                            Image(systemName: settings.position == .topCenter ? "chevron.up.2" : (settings.position.rawValue.contains("left") ? "chevron.left.2" : "chevron.right.2"))
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(viewModel.hoverHide ? .blue : .gray)
                                .frame(width: 24, height: 24)
                                .background(viewModel.hoverHide ? Color.gray.opacity(0.15) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                        .onHover { viewModel.hoverHide = $0 }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .padding(.bottom, 6)
                    .background(settings.position == .topCenter ? Color.white.opacity(0.05) : Color(NSColor.windowBackgroundColor).opacity(0.1))
                    .contentShape(Rectangle())
                    .onTapGesture { 
                        viewModel.deselectAll()
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                    
                    Divider()
                    
                    // ================= CONTENT =================
                    ZStack {
                        if viewModel.showingSettings {
                            SettingsView(viewModel: viewModel)
                                .padding()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(NSColor.windowBackgroundColor))
                        } else if viewModel.files.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "tray.and.arrow.down")
                                    .font(.system(size: 30))
                                    .foregroundColor(settings.position == .topCenter ? .gray.opacity(0.5) : .secondary.opacity(0.5))
                                Text("Drop Files Here")
                                    .font(.headline)
                                    .foregroundColor(settings.position == .topCenter ? .gray : .secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                        } else {
                            ScrollView(.vertical, showsIndicators: true) {
                                LazyVGrid(columns: columns, spacing: 15) {
                                    ForEach(viewModel.files) { item in
                                        FileView(
                                            item: item,
                                            isSelected: viewModel.selectedIds.contains(item.id),
                                            viewModel: viewModel,
                                            onRemove: { viewModel.removeFile(withURL: item.url) }
                                        )
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 15)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(key: GridHeightPreferenceKey.self, value: geo.size.height)
                                    }
                                )
                            }
                            .frame(height: min(viewModel.gridContentHeight, maxAllowedContentHeight))
                            .onPreferenceChange(GridHeightPreferenceKey.self) { newHeight in
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.gridContentHeight = newHeight
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { 
                        viewModel.deselectAll()
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.keyWindow?.makeFirstResponder(nil)
                    }
                    .background(
                        Button("") { viewModel.selectAll() }
                            .keyboardShortcut("a", modifiers: .command)
                            .buttonStyle(.plain)
                            .allowsHitTesting(false)
                            .opacity(0)
                    )
                    
                    Divider()
                    
                    // ================= FOOTER =================
                    HStack {
                        if !viewModel.files.isEmpty {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) { viewModel.clearAll() }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "broom.fill")
                                        .font(.system(size: 13))
                                    Text("Clear All")
                                        .font(.system(size: 11, weight: .medium))
                                }
                                .foregroundColor(viewModel.hoverClear ? .blue : .blue.opacity(0.8))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(viewModel.hoverClear ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                            .onHover { viewModel.hoverClear = $0 }
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                    .background(Color(NSColor.windowBackgroundColor).opacity(0.05))
                    .contentShape(Rectangle())
                    .onTapGesture { 
                        viewModel.deselectAll()
                        NSApp.activate(ignoringOtherApps: true)
                    }
                }
                .frame(width: settings.position == .topCenter ? 348 : 300)
                .background(settings.position == .topCenter ? Color.black.opacity(0.95) : Color(NSColor.windowBackgroundColor).opacity(0.95))
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: settings.position == .topCenter ? 0 : 16,
                    bottomLeadingRadius: 16,
                    bottomTrailingRadius: 16,
                    topTrailingRadius: settings.position == .topCenter ? 0 : 16
                ))
                .onHover { hovering in
                    viewModel.isHovered = hovering
                    // Local onHover logic for other positions
                    if !hovering && settings.position != .topCenter {
                        viewModel.collapseTimer?.invalidate()
                        viewModel.collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                            guard !viewModel.isHovered && !viewModel.showingSettings && !settings.isDraggingOut else { return }
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                settings.isCollapsed = true
                            }
                        }
                    } else {
                        viewModel.collapseTimer?.invalidate()
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Push content to the top for topCenter since the NSWindow is permanently full-size
            if settings.position == .topCenter {
                Spacer()
            }
        } // Closes the new VStack
        .frame(width: settings.position == .topCenter ? 348 : 300)
        } // Closes the Group
        .onChange(of: settings.isCollapsed) { collapsed in
            if settings.position == .topCenter {
                if !collapsed {
                    startGlobalHoverCheck()
                } else {
                    viewModel.hoverTimer?.invalidate()
                }
            }
        }
        .onChange(of: viewModel.showingSettings) { showing in
            if !showing {
                // When settings close, we check if we should auto-collapse based on current mouse position
                if settings.position != .topCenter {
                    // For side edges, if mouse is not hovering the main window, we must start the timer manually
                    // because closing the popover doesn't trigger an onHover event if the mouse is over the desktop
                    if !viewModel.isHovered {
                        viewModel.collapseTimer?.invalidate()
                        viewModel.collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                            guard !viewModel.isHovered && !viewModel.showingSettings && !settings.isDraggingOut else { return }
                            withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                                settings.isCollapsed = true
                            }
                        }
                    }
                } else {
                    // For topCenter, the continuous startGlobalHoverCheck will naturally pick it up,
                    // but we can force an immediate check just to be perfectly responsive.
                }
            }
        }
        .onTapGesture {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: geo.size.height)
            }
        )
        .onPreferenceChange(ContentHeightPreferenceKey.self) { newHeight in
            if !(settings.position == .topCenter && settings.isCollapsed) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .windowHeightChanged, object: nil, userInfo: ["height": newHeight])
                }
            }
        }
        .frame(maxHeight: maxWindowHeight)
        .animation(.snappy(duration: 0.2), value: viewModel.files.count)
        .animation(.snappy, value: settings.displayCount)
        .onAppear {
            DispatchQueue.main.async {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
        .onChange(of: viewModel.files.isEmpty) { isEmpty in
            if isEmpty {
                withAnimation(.snappy(duration: 0.2)) {
                    viewModel.gridContentHeight = 0
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: Binding(
            get: { viewModel.isDragOver },
            set: { viewModel.isDragOver = $0 }
        )) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            viewModel.addFile(url: url)
                        }
                    }
                }
            }
            return true
        }
        .onChange(of: viewModel.isDragOver) { over in
            if over && settings.position == .topCenter && settings.isCollapsed {
                withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                    settings.isCollapsed = false
                }
            }
        }
        .ignoresSafeArea(.all, edges: .vertical)
    }
    
    private var maxAllowedContentHeight: CGFloat {
        if viewModel.files.isEmpty { return 120 }
        let rows = ceil(Double(settings.displayCount) / 3.0)
        return (CGFloat(rows) * 110) + 30
    }
    
    // Global hover check to handle macOS notch deadzones
    private func startGlobalHoverCheck() {
        viewModel.hoverTimer?.invalidate()
        viewModel.hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Only kill the timer if we are completely collapsed or moved away from topCenter
            guard !settings.isCollapsed, settings.position == .topCenter else {
                viewModel.hoverTimer?.invalidate()
                return
            }
            
            // Just pause the tracking if settings are open or dragging
            guard !viewModel.showingSettings, !settings.isDraggingOut else { return }
            
            // Check global mouse position against a safe zone (window center + ~200px padding)
            let mouseLoc = NSEvent.mouseLocation
            guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) else { return }
            
            let safeWidth: CGFloat = 348 + 100 // 50px padding on each side
            let safeHeight: CGFloat = self.maxAllowedContentHeight + notchHeight + 100
            
            let minX = screen.frame.midX - (safeWidth / 2)
            let maxX = screen.frame.midX + (safeWidth / 2)
            let minY = screen.frame.maxY - safeHeight
            let maxY = screen.frame.maxY
            
            let isInside = mouseLoc.x >= minX && mouseLoc.x <= maxX && mouseLoc.y >= minY && mouseLoc.y <= maxY
            
            if !isInside {
                // Only start the 0.4s timer if we haven't already started it
                if viewModel.collapseTimer == nil || !viewModel.collapseTimer!.isValid {
                    viewModel.collapseTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false) { _ in
                        let currentMouse = NSEvent.mouseLocation
                        let stillOutside = !(currentMouse.x >= minX && currentMouse.x <= maxX && currentMouse.y >= minY && currentMouse.y <= maxY)
                        
                        if stillOutside && !viewModel.showingSettings && !settings.isDraggingOut {
                            withAnimation(.spring(response: 0.4, dampingFraction: 1.0)) {
                                settings.isCollapsed = true
                            }
                            viewModel.hoverTimer?.invalidate()
                        }
                    }
                }
            } else {
                viewModel.collapseTimer?.invalidate()
                viewModel.collapseTimer = nil
            }
        }
    }
}

// MARK: - Native Drag-and-Drop Overlay (Polished with Hit-Testing)
struct NativeDragOverlay: NSViewRepresentable {
    let urls: () -> [URL]
    let onTap: () -> Void
    let onDragStarted: () -> Void
    let onDragEnded: (NSDragOperation) -> Void
    let onHover: (Bool) -> Void
    
    func makeNSView(context: Context) -> NativeDragView {
        let view = NativeDragView()
        view.urlsProvider = urls
        view.onTap = onTap
        view.onDragStarted = onDragStarted
        view.onDragEnded = onDragEnded
        view.onHoverChange = onHover
        return view
    }
    
    func updateNSView(_ nsView: NativeDragView, context: Context) {
        nsView.urlsProvider = urls
        nsView.onTap = onTap
        nsView.onDragStarted = onDragStarted
        nsView.onDragEnded = onDragEnded
        nsView.onHoverChange = onHover
    }
}

class NativeDragView: NSView, NSDraggingSource {
    var urlsProvider: (() -> [URL])?
    var onTap: (() -> Void)?
    var onDragStarted: (() -> Void)?
    var onDragEnded: ((NSDragOperation) -> Void)?
    var onHoverChange: ((Bool) -> Void)?
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
    
    private var dragStartLocation: NSPoint?
    private var hasInitiatedDrag = false
    private var trackingArea: NSTrackingArea?
    
    // Hit-testing bypass for the removal button area
    override func hitTest(_ point: NSPoint) -> NSView? {
        let removalZone = NSRect(x: bounds.width - 25, y: bounds.height - 25, width: 25, height: 25)
        if removalZone.contains(point) {
            return nil // Let event through to SwiftUI content below
        }
        return super.hitTest(point)
    }
    
    override func updateTrackingAreas() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }
    
    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
    }
    
    override func mouseDown(with event: NSEvent) {
        dragStartLocation = event.locationInWindow
        hasInitiatedDrag = false
    }
    
    override func mouseUp(with event: NSEvent) {
        if !hasInitiatedDrag {
            onTap?()
        }
        dragStartLocation = nil
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard let startLocation = dragStartLocation, !hasInitiatedDrag else { return }
        let currentLocation = event.locationInWindow
        let distance = sqrt(pow(currentLocation.x - startLocation.x, 2) + pow(currentLocation.y - startLocation.y, 2))
        
        if distance > 5 {
            hasInitiatedDrag = true
            initiateDrag(with: event)
        }
    }
    
    private func initiateDrag(with event: NSEvent) {
        guard let urls = urlsProvider?(), !urls.isEmpty else { return }
        
        let draggingItems = urls.map { url -> NSDraggingItem in
            let item = NSDraggingItem(pasteboardWriter: url as NSURL)
            item.setDraggingFrame(NSRect(x: 0, y: 0, width: 70, height: 70), contents: nil)
            return item
        }
        
        onDragStarted?()
        self.beginDraggingSession(with: draggingItems, event: event, source: self)
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.copy, .move]
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        var finalOperation = operation
        if let windowFrame = self.window?.frame, windowFrame.contains(screenPoint) {
            finalOperation = []
        }
        
        DispatchQueue.main.async {
            self.onDragEnded?(finalOperation)
        }
    }
}

// MARK: - File View
struct FileView: View {
    let item: FileItem
    var isSelected: Bool
    @ObservedObject var viewModel: FileShelfViewModel
    var onRemove: () -> Void
    
    var isHovering: Bool {
        viewModel.hoveringItemIds.contains(item.id)
    }
    var isOptionPressed: Bool {
        viewModel.optionPressedItemIds.contains(item.id)
    }
    
    var body: some View {
        ZStack {
            // UI Layer (Visuals + Small Buttons)
            VStack {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if let thumb = item.thumbnail {
                            Image(nsImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 60, height: 60)
                        } else {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.3))
                        }
                    }
                    .frame(width: 70, height: 70)
                    .background(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
                    
                    if isOptionPressed {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                            .offset(x: -5, y: -5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    }
                    
                    if isHovering {
                        Button(action: {
                            withAnimation(.snappy(duration: 0.2)) {
                                onRemove()
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.red)
                                .background(Circle().fill(Color.white))
                        }
                        .buttonStyle(.plain)
                        .offset(x: 5, y: -5)
                        .zIndex(10)
                    }
                }
                
                Text(item.fileName)
                    .font(.system(size: 10, weight: .medium))
                    .lineLimit(1)
                    .frame(width: 80)
            }
            .contentShape(Rectangle())
            
            // Interaction Overlay (Native Drag & Selection)
            NativeDragOverlay(
                urls: {
                    isSelected ? viewModel.selectedFiles.map { $0.url } : [item.url]
                },
                onTap: {
                    let flags = NSEvent.modifierFlags
                    viewModel.selectItem(item.id, cumulative: flags.contains(.command), shift: flags.contains(.shift))
                    NSApp.activate(ignoringOtherApps: true)
                },
                onDragStarted: {
                    AppSettings.shared.isDraggingOut = true
                },
                onDragEnded: { operation in
                    AppSettings.shared.isDraggingOut = false
                    if operation != [] {
                        let isCopy = NSEvent.modifierFlags.contains(.option)
                        if !isCopy {
                            if isSelected {
                                let urlsToRemove = viewModel.selectedFiles.map { $0.url }
                                for url in urlsToRemove { viewModel.removeFile(withURL: url) }
                            } else {
                                viewModel.removeFile(withURL: item.url)
                            }
                        }
                    }
                },
                onHover: { hovering in
                    if hovering {
                        viewModel.hoveringItemIds.insert(item.id)
                    } else {
                        viewModel.hoveringItemIds.remove(item.id)
                    }
                    if NSEvent.modifierFlags.contains(.option) {
                        viewModel.optionPressedItemIds.insert(item.id)
                    } else {
                        viewModel.optionPressedItemIds.remove(item.id)
                    }
                }
            )
            .frame(width: 80, height: 100)
            .zIndex(1)
        }
    }
}

// MARK: - Helpers
struct GridHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

extension NSNotification.Name {
    static let windowHeightChanged = NSNotification.Name("windowHeightChanged")
}

struct SettingsView: View {
    @ObservedObject var viewModel: FileShelfViewModel
    @ObservedObject var settings = AppSettings.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Settings").font(.headline)
            Picker("Position", selection: $settings.position) {
                ForEach(ScreenPosition.allCases) { pos in
                    Text(pos.name).tag(pos)
                }
            }
            Picker("Show Max Items", selection: $settings.displayCount) {
                Text("1").tag(1)
                Text("3 (1 Row)").tag(3)
                Text("6 (2 Rows)").tag(6)
                Text("9 (3 Rows)").tag(9)
            }
            Divider()
            
            HStack(spacing: 12) {
                Button("Restart App") {
                    let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
                    let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
                    let task = Process()
                    task.launchPath = "/usr/bin/open"
                    task.arguments = [path]
                    task.launch()
                    exit(0)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Spacer()
                
                QuitButton()
                    .frame(width: 68, height: 20)
            }
        }
        .frame(width: 240)
    }
}

// MARK: - Native QuitButton Wrapper (Bypassing @State on CLI)
class HoverButton: NSButton {
    private var trackingArea: NSTrackingArea?
    private var isHovered = false {
        didSet {
            needsDisplay = true
        }
    }
    
    override func updateTrackingAreas() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
        super.updateTrackingAreas()
    }
    
    override func mouseEntered(with event: NSEvent) {
        isHovered = true
    }
    
    override func mouseExited(with event: NSEvent) {
        isHovered = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        if isHovered {
            NSColor.systemRed.setFill()
            let path = NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5)
            path.fill()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let size = title.size(withAttributes: attrs)
            let rect = NSRect(x: 0, y: (bounds.height - size.height)/2, width: bounds.width, height: size.height)
            title.draw(in: rect, withAttributes: attrs)
        } else {
            NSColor.clear.setFill()
            let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 5, yRadius: 5)
            path.fill()
            NSColor.separatorColor.setStroke()
            path.lineWidth = 1
            path.stroke()
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.textColor,
                .paragraphStyle: paragraphStyle
            ]
            let size = title.size(withAttributes: attrs)
            let rect = NSRect(x: 0, y: (bounds.height - size.height)/2, width: bounds.width, height: size.height)
            title.draw(in: rect, withAttributes: attrs)
        }
    }
}

struct QuitButton: NSViewRepresentable {
    func makeNSView(context: Context) -> HoverButton {
        let button = HoverButton()
        button.title = "Quit App"
        button.target = context.coordinator
        button.action = #selector(Coordinator.quit)
        button.isBordered = false
        button.wantsLayer = true
        return button
    }
    
    func updateNSView(_ nsView: HoverButton, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        @objc func quit() {
            NSApp.terminate(nil)
        }
    }
}

// MARK: - Notch & Capsule Elements
struct NotchShape: Shape {
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                    radius: radius,
                    startAngle: Angle(degrees: 0),
                    endAngle: Angle(degrees: 90),
                    clockwise: false)
                    
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                    radius: radius,
                    startAngle: Angle(degrees: 90),
                    endAngle: Angle(degrees: 180),
                    clockwise: false)
                    
        path.closeSubpath()
        return path
    }
}

struct CollapsedNotchView: View {
    @ObservedObject var viewModel: FileShelfViewModel
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        // Fully hidden behind the physical notch - just be transparent and tiny
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: 1)
    }
}
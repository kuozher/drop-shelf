import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @StateObject var viewModel = FileShelfViewModel()
    @StateObject var settings = AppSettings.shared
    
    // UI State
    @State private var showingSettings = false
    @State private var hoverSettings = false
    @State private var hoverHide = false
    @State private var hoverClear = false
    
    // Layout State
    @State private var gridContentHeight: CGFloat = 0
    
    // Grid Configuration
    let columns = [
        GridItem(.fixed(80)),
        GridItem(.fixed(80)),
        GridItem(.fixed(80))
    ]
    
    // Max allowable height for the window
    let maxWindowHeight: CGFloat = 600
    
    var body: some View {
        VStack(spacing: 0) {
            
            // ================= HEADER =================
            HStack(spacing: 8) {
                Text("\(viewModel.files.count) items")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                
                if viewModel.selectedCount > 0 {
                    Text("(\(viewModel.selectedCount) selected)")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Settings Button
                Button(action: { showingSettings.toggle() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14))
                        .foregroundColor(hoverSettings ? .blue : .gray)
                        .frame(width: 24, height: 24)
                        .background(hoverSettings ? Color.gray.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .onHover { hoverSettings = $0 }
                .popover(isPresented: $showingSettings) {
                    SettingsView(settings: settings)
                        .padding()
                }
                
                // Hide Button
                Button(action: {
                    NSApp.sendAction(#selector(AppDelegate.hideWindow), to: nil, from: nil)
                }) {
                    Image(systemName: settings.position.rawValue.contains("left") ? "chevron.left.2" : "chevron.right.2")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(hoverHide ? .blue : .gray)
                        .frame(width: 24, height: 24)
                        .background(hoverHide ? Color.gray.opacity(0.15) : Color.clear)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .onHover { hoverHide = $0 }
            }
            .padding(.horizontal, 12)
            .padding(.top, 4) // Reduced from 8 to force top alignment
            .padding(.bottom, 6)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.1))
            .contentShape(Rectangle())
            .onTapGesture { 
                viewModel.deselectAll()
                NSApp.activate(ignoringOtherApps: true)
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
            
            Divider()
            
            // ================= CONTENT =================
            ZStack {
                if viewModel.files.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 30))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Drop Files Here")
                            .font(.headline)
                            .foregroundColor(.secondary)
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
                    .frame(height: min(gridContentHeight, maxAllowedContentHeight))
                    .onPreferenceChange(GridHeightPreferenceKey.self) { newHeight in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            self.gridContentHeight = newHeight
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
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
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
                        .foregroundColor(hoverClear ? .blue : .blue.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(hoverClear ? Color.blue.opacity(0.2) : Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .onHover { hoverClear = $0 }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 4) // Reduced from 6 to force bottom alignment
            .background(Color(NSColor.windowBackgroundColor).opacity(0.05))
            .contentShape(Rectangle())
            .onTapGesture { 
                viewModel.deselectAll()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .frame(width: 300)
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
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .windowHeightChanged, object: nil, userInfo: ["height": newHeight])
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
                    self.gridContentHeight = 0
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
}

// MARK: - Native Drag-and-Drop Overlay (Polished with Hit-Testing)
struct NativeDragOverlay: NSViewRepresentable {
    let urls: () -> [URL]
    let onTap: () -> Void
    let onDragEnded: (NSDragOperation) -> Void
    let onHover: (Bool) -> Void
    
    func makeNSView(context: Context) -> NativeDragView {
        let view = NativeDragView()
        view.urlsProvider = urls
        view.onTap = onTap
        view.onDragEnded = onDragEnded
        view.onHoverChange = onHover
        return view
    }
    
    func updateNSView(_ nsView: NativeDragView, context: Context) {
        nsView.urlsProvider = urls
        nsView.onTap = onTap
        nsView.onDragEnded = onDragEnded
        nsView.onHoverChange = onHover
    }
}

class NativeDragView: NSView, NSDraggingSource {
    var urlsProvider: (() -> [URL])?
    var onTap: (() -> Void)?
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
        // Red minus button area: top-right corner in AppKit coordinates (0,0 is bottom-left)
        // Overlay frame is 80x100.
        // SwiftUI Button is centered in a ZStack but offset.
        // Let's create a 25x25 bypass zone at the top-right.
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
        
        self.beginDraggingSession(with: draggingItems, event: event, source: self)
    }
    
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.copy, .move]
    }
    
    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // Guard: If the drop happens INSIDE our own window, ignore any "Move" command.
        // This prevents accidental removal when dragging items back to the shelf.
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
    @State private var isHovering = false
    @State private var isOptionPressed = false
    
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
                        .zIndex(10) // Ensure it's on top within this ZStack
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
                onDragEnded: { operation in
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
                    self.isHovering = hovering
                    self.isOptionPressed = NSEvent.modifierFlags.contains(.option)
                }
            )
            .frame(width: 80, height: 100)
            .zIndex(1) // Overlay is above visuals but bypasses hit testing for the minus button
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
    @ObservedObject var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
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
                // Restart Button: Prominent Blue
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
                
                // Quit Button: Outline (Gray) -> Hover (Solid Red)
                QuitButton()
            }
        }
        .frame(width: 240)
    }
}

struct QuitButton: View {
    @State private var isHovering = false
    
    var body: some View {
        Button(action: {
            NSApp.terminate(nil)
        }) {
            Text("Quit App")
                .font(.system(size: 11)) // Match standard small control size font
                .foregroundColor(isHovering ? .white : .primary)
                .frame(height: 20) // Standard small button height
                .padding(.horizontal, 8)
                .background(
                    ZStack {
                        if isHovering {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.red)
                        } else {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        }
                    }
                )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}
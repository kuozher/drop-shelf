# DropShelf Development Log

## 1. Project Inception: The "Floating Shelf" Concept
**Goal**: Create a native macOS utility that acts as a temporary holding zone (shelf) for drag-and-drop operations, similar to "Yoink" or "Dropover" but lightweight.

### 1.1 Core Architecture
- **Technology**: SwiftUI for UI, AppKit for window management.
- **Window Type**: `NSPanel` with `.nonactivatingPanel` style mask. This was crucial to ensure the window floats above others (`.floating` level) but **does not steal focus** when interacted with.

## 2. Interaction Design: Triggers & Visibility
**Challenge**: How does the user summon the shelf without a dock icon click?

### 2.1 Edge Trigger
- Implemented `EdgeTrigger.swift` using `NSEvent.addGlobalMonitorForEvents`.
- **Evolution**: Initially triggered on the entire right edge. Later refined to be **Screen Position Aware** (checking Top/Bottom/Right/Left based on settings).
- **Refinement**: Added "Dead Zones" (Top 30% / Bottom 30%) to prevent accidental triggers (e.g., when closing windows or using the Dock).

### 2.2 Shake Trigger (Iterated Out)
- **Initial Logic**: Added logic to detect rapid cursor movement (Shake) while dragging a file.
- **Refinement**: Removed after user feedback indicated high false-positive rates in design applications like Figma. Deterministic edge triggering was chosen as the superior UX.

## 3. The Drag-and-Drop Saga
**Challenge**: SwiftUI's native `onDrag` was insufficient for complex file interactions (especially moving files *out* of the app).

### 3.1 The SwiftUI Limitation
- Standard SwiftUI drag caused the window to disappear or blocked the drop operation because the app wasn't "active".

### 3.2 The AppKit Solution (`NativeDragOverlay`)
- Built a bridge `NativeDragView` (inheriting from `NSView` and implementing `NSDraggingSource`).
- **Breakthrough**: Used a transparent overlay on top of the file icons.
- **Move vs. Copy**: Implemented standard macOS logic. Default is **Move** (remove from shelf), holding Option key toggles **Copy**.
- **Internal Guard**: Added logic to detect if a distinct "drop" occurred back inside the DropShelf window, cancelling the operation to prevent accidental deletion.

### 3.3 "First Mouse" Experience
- Implemented `acceptsFirstMouse` in the AppKit view.
- **Result**: Users can click and drag an item immediately even if DropShelf is in the background (inactive), removing the need for a "double click" (one to focus, one to act).

## 4. UI/UX Polish
- **Dynamic Resizing**: Window height now animates (`spring`) based on the number of items.
- **Smart Layout**:
  - "Clear All" button hides when empty.
  - Header/Footer padding reduced to 4px for a compact, utility-style aesthetic.
- **Focus Management**: Explicitly cleared `First Responder` on background taps to prevent blue focus rings on buttons.
- **Settings UI**:
  - Custom "Quit App" button design (Outline style, Solid Red on Hover).

## 5. Security & Packaging (The "Pro" Finish)
**Challenge**: macOS Sandbox and Gatekeeper warnings.

### 5.1 Sandbox Entitlements
- Added `com.apple.security.files.user-selected.read-write`. This allows the app to accept dropped files without prompting the user for permission *every single time*.

### 5.2 Ad-hoc Signing & Automation
- created `package.sh`: Automates `swift build`, strips resource detritus (`xattr -cr`), and performs ad-hoc codesigning.
- **Icon Processing**: Integrated `sips` and `iconutil` into the build script to automatically convert `assets/icon.png` into a native `.icns` bundle.
- created `create_dmg.sh`: Bundles the app into a collaborative DMG with a `/Applications` symlink for easy installation.

## 6. GitHub Readiness
- **README & Badges**: Created a professional `README.md` and added Shields.io badges for quick project insight (Version, License, Platform).
- **Environment**: Configured `.gitignore` to exclude build artifacts while keeping documentation and assets tracked.

## Summary
DropShelf evolved from a simple window test into a robust, "Mac-assed Mac App" workflow tool. It handles native file system events, respects user focus, and behaves with the polish expected of a system utility.

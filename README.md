<img width="150" height="150" alt="Image" src="https://github.com/user-attachments/assets/50471d12-2064-4bdf-8227-bbe055ea55fd" />

# DropShelf

![Platform](https://img.shields.io/badge/platform-macOS-lightgrey)
![Language](https://img.shields.io/badge/language-Swift_5-orange)
![License](https://img.shields.io/badge/license-MIT-blue)
![Version](https://img.shields.io/badge/version-1.0.0-green)

**DropShelf** is a lightweight, native macOS utility that makes drag-and-drop operations easier. It provides a temporary "shelf" to hold files, images, and text while you navigate between different applications or spaces.

## 🖼️ Screenshots
<details>
  <summary><b>🔍 show</b></summary>
  <br>
<table width="100%">
    <tr>
      <td align="center" width="50%">
        <img src="https://github.com/user-attachments/assets/22297d07-f307-4968-9860-88dacfbfaecc" alt="Basic View" /><br>
        <kbd>Basic View</kbd>
      </td>
      <td align="center" width="50%">
        <img src="https://github.com/user-attachments/assets/fe3f9c3b-057d-41c3-88d4-95a8862c3c7c" alt="settings" /><br>
        <kbd>settings</kbd>
      </td>
    </tr>
</table>
</details>

## ✨ Features

- **Float on Top**: Always accessible but never steals focus (`NSPanel`).
- **Smart Triggers**:
  - **Dynamic Edge Trigger**: Trigger area adjusts based on screen position setting (Top/Center/Bottom) to avoid accidental activation.
  - **Flick Activation**: Simply flick your mouse to the designated edge zone.
- **Native Drag & Drop**:
  - **First Mouse Support**: Drag items out directly from the background without clicking to focus first.
  - **Move/Copy Logic**: Default to Move; hold `Option` to Copy.
- **Modern macOS UI**:
  - Native visual effects and animations.
  - Dark/Light mode support.
  - Adaptive window resizing.

## 🚀 Installation

### Option 1: Download DMG
1. Download the latest `DropShelf.dmg` from the Releases page.
2. Drag **DropShelf.app** to your **Applications** folder.
3. **Important**: On first launch, Right-Click the app and select **Open** to bypass macOS security checks (since this is an open-source, non-notarized build).

### Option 2: Build from Source
Requirements: macOS 12.0+, Xcode 14+ (or Swift Toolchain).

```bash
# Clone the repository
git clone https://github.com/kuozher/drop-shelf.git
cd DropShelf

# Build and Sign
./package.sh

# The app will be created in the current directory:
open DropShelf.app
```

## 🛠 Usage
1. **Drag** a file from Finder or an image from the Web.
2. **Move** your mouse to the **Screen Edge** (Top/Center/Bottom zone). DropShelf appears.
3. **Drop** the item onto the shelf.
4. Navigate to your destination (e.g., Email, Slack, another folder).
5. **Drag** the item *from* DropShelf to your destination.

## ⚙️ Settings
Click the **Gear Icon** to customize:
- **Position**: Left/Right edge, Top/Center/Bottom alignment.
- **Display Limit**: How many items to show at once.
- **Quit/Restart**: App management controls.

## 📝 License
MIT License. Feel free to modify and distribute.


## ✍️ Author's Note

Initially, my goal was simply to create a lightweight alternative to Adobe Reader, despite having limited knowledge of deep frontend or backend coding. Consequently, the execution of this project was entrusted almost entirely to AI—specifically, 90% of the code was generated using the Google Antigravity, with my role serving as the adjudicator of its suggestions.

I realize some might dismiss this as just another piece of 'AI slop' created by someone who doesn't understand the underlying code rules. However, that doesn't matter to me. When problems arose, they were solved; when decisions were needed, I grasped the context and acted on logic. A tool is ultimately just a tool, and my only hope is that the final product brings real value to its users.
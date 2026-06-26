import AppKit

print("normal:", NSWindow.Level.normal.rawValue)
print("floating:", NSWindow.Level.floating.rawValue)
print("statusBar:", NSWindow.Level.statusBar.rawValue)
print("popUpMenu:", NSWindow.Level.popUpMenu.rawValue)
print("screenSaver:", NSWindow.Level.screenSaver.rawValue)
print("CGShielding:", CGShieldingWindowLevel())
print("maximum:", CGWindowLevelForKey(.maximumWindowLevelKey))
print("overlay:", CGWindowLevelForKey(.overlayWindowLevelKey))

import SwiftUI

enum ScreenPosition: String, CaseIterable, Identifiable {
    case leftTop, leftCenter, leftBottom
    case rightTop, rightCenter, rightBottom
    case topCenter
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .leftTop: return "Left Top"
        case .leftCenter: return "Left Center"
        case .leftBottom: return "Left Bottom"
        case .rightTop: return "Right Top"
        case .rightCenter: return "Right Center"
        case .rightBottom: return "Right Bottom"
        case .topCenter: return "Top Center"
        }
    }
}

class AppSettings: ObservableObject {
    @Published var position: ScreenPosition = .rightCenter {
        didSet {
            UserDefaults.standard.set(position.rawValue, forKey: "screenPosition")
        }
    }
    @Published var displayCount: Int = 3 {
        didSet {
            UserDefaults.standard.set(displayCount, forKey: "displayCount")
        }
    }
    
    @Published var isCollapsed: Bool = true
    @Published var isDraggingOut: Bool = false
    
    static let shared = AppSettings()
    
    private init() {
        // Load initial values from UserDefaults manually
        let savedPosRaw = UserDefaults.standard.string(forKey: "screenPosition") ?? ""
        self.position = ScreenPosition(rawValue: savedPosRaw) ?? .rightCenter
        
        let savedCount = UserDefaults.standard.integer(forKey: "displayCount")
        self.displayCount = savedCount > 0 ? savedCount : 3
        
        self.isCollapsed = true
    }
}

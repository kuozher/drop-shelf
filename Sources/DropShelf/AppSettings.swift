import SwiftUI

enum ScreenPosition: String, CaseIterable, Identifiable {
    case leftTop, leftCenter, leftBottom
    case rightTop, rightCenter, rightBottom
    
    var id: String { self.rawValue }
    
    var name: String {
        switch self {
        case .leftTop: return "Left Top"
        case .leftCenter: return "Left Center"
        case .leftBottom: return "Left Bottom"
        case .rightTop: return "Right Top"
        case .rightCenter: return "Right Center"
        case .rightBottom: return "Right Bottom"
        }
    }
}

class AppSettings: ObservableObject {
    @AppStorage("screenPosition") var position: ScreenPosition = .rightCenter
    @AppStorage("displayCount") var displayCount: Int = 3 // 1, 3, 6, 9
    
    static let shared = AppSettings()
}

import Foundation

enum InjectionMode: String, CaseIterable, Identifiable {
    case coordinates
    case nativeSpeed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .coordinates: return "Coordinates"
        case .nativeSpeed: return "Native speed helper (experimental)"
        }
    }
}

import Foundation
import SwiftUI

public enum Provider: String, Codable, CaseIterable, Identifiable, Sendable {
    case openAI = "openai"
    case anthropic
    case openRouter = "openrouter"

    public var id: String {
        rawValue
    }

    public var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        case .openRouter: "OpenRouter"
        }
    }

    public var accentColor: Color {
        switch self {
        case .openAI: Color(hex: "10A37F")
        case .anthropic: Color(hex: "CC785C")
        case .openRouter: Color(hex: "E63946")
        }
    }

    public var iconName: String {
        switch self {
        case .openAI: "brain"
        case .anthropic: "cpu"
        case .openRouter: "network"
        }
    }

    public var keychainService: String {
        "com.icodexbar.keychain.\(rawValue)"
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let alpha, red, green, blue: UInt64
        switch hex.count {
        case 3:
            (alpha, red, green, blue) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (alpha, red, green, blue) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (alpha, red, green, blue) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (alpha, red, green, blue) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
        )
    }
}

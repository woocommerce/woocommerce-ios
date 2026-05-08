import SwiftUI
import UIKit
import WooFoundation

public extension Color {
    static let assistantSurface = Color(.systemBackground)
    static let assistantSurfaceElevated = Color(.tertiarySystemFill)
    static let assistantSurfaceBorder = Color(.divider).opacity(0.35)
    static let assistantSeparator = Color(.divider)
    static let assistantBubbleUser = Color(.accent)
    static let assistantBubbleUserText = Color.assistantOnAccent
    static let assistantOnAccent = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(white: 0.08, alpha: 1.0) : .white
    })
    static let assistantBubbleAssistant = Color(.tertiarySystemFill)
    static let assistantBubbleAssistantText = Color(.text)
    static let assistantMuted = Color(.textSubtle)
    static let assistantTextFaint = Color(.textTertiary)
    static let assistantToolBackground = Color(.tertiarySystemFill)
    static let assistantError = Color(.error)
    static let assistantSuccess = Color(.success)
    static let assistantWarning = Color(.warning)
    static let assistantInfo = Color(.info)
}

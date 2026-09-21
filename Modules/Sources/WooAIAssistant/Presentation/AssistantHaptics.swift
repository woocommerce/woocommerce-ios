import UIKit

@MainActor
enum AssistantHaptics {
    private static let generator = UIImpactFeedbackGenerator(style: .soft)

    /// Fires a soft tap used to mark new chat segments arriving.
    static func gentleTap() {
        generator.prepare()
        generator.impactOccurred()
    }
}

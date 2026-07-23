import SwiftUI

/// A decorative, non-interactive icon rendered inside a rounded, tone-colored container.
///
/// - Note: Purely decorative by default (`accessibilityLabel` is `nil`), so VoiceOver skips it.
///   Supply an `accessibilityLabel` when the icon conveys meaning that isn't already announced by a
///   surrounding element.
public struct StoreIconContainer: View {
    private let icon: StoreIconImage
    private let tone: StoreIconContainerTone
    private let accessibilityLabel: String?

    public init(_ icon: StoreIconImage,
                tone: StoreIconContainerTone = .purple,
                accessibilityLabel: String? = nil) {
        self.icon = icon
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        icon.image(size: Constants.iconSize)
            .foregroundStyle(tone.appearance.foreground)
            .frame(width: StoreSize.iconContainerSize, height: StoreSize.iconContainerSize)
            .background(tone.appearance.background)
            .clipShape(RoundedRectangle(cornerRadius: StoreRadius.medium))
            .accessibilityElement()
            .accessibilityAddTraits(.isImage)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHidden(accessibilityLabel == nil)
    }
}

private extension StoreIconContainer {
    enum Constants {
        static let iconSize: StoreIconSize = .medium
    }
}

import SwiftUI

/// A decorative, non-interactive icon rendered inside a rounded, tone-colored container.
///
/// - Note: Purely decorative by default (`accessibilityLabel` is `nil`), so VoiceOver skips it.
///   Supply an `accessibilityLabel` when the icon conveys meaning that isn't already announced by a
///   surrounding element.
public struct StoreIconContainer: View {
    private let icon: Icon
    private let tone: StoreIconContainerTone
    private let accessibilityLabel: String?

    public init(_ icon: StoreIconImage,
                tone: StoreIconContainerTone = .purple,
                accessibilityLabel: String? = nil) {
        self.icon = .store(icon)
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }

    /// Creates an icon container for custom artwork, such as a brand logo.
    public init(_ image: Image,
                size: StoreIconSize = .medium,
                tone: StoreIconContainerTone = .purple,
                accessibilityLabel: String? = nil) {
        self.icon = .custom(image, size: size)
        self.tone = tone
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        iconView
            .foregroundStyle(tone.appearance.foreground)
            .frame(width: StoreSize.iconContainerSize, height: StoreSize.iconContainerSize)
            .background(tone.appearance.background)
            .clipShape(RoundedRectangle(cornerRadius: StoreRadius.medium))
            .accessibilityElement()
            .accessibilityAddTraits(.isImage)
            .accessibilityLabel(accessibilityLabel ?? "")
            .accessibilityHidden(accessibilityLabel == nil)
    }

    @ViewBuilder
    private var iconView: some View {
        switch icon {
        case .store(let icon):
            icon.image(size: Constants.iconSize)
        case let .custom(image, size):
            image
                .resizable()
                .scaledToFit()
                .frame(width: size.value, height: size.value)
        }
    }
}

private extension StoreIconContainer {
    enum Icon {
        case store(StoreIconImage)
        case custom(Image, size: StoreIconSize)
    }

    enum Constants {
        static let iconSize: StoreIconSize = .medium
    }
}

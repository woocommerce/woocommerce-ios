import SwiftUI

public struct StoreBadge: View {
    private let title: String
    private let icon: StoreIconImage?
    private let tone: StoreBadgeTone

    public init(_ title: String,
                icon: StoreIconImage? = nil,
                tone: StoreBadgeTone = .neutral) {
        self.title = title
        self.icon = icon
        self.tone = tone
    }

    public var body: some View {
        HStack(spacing: StoreSpacing.s2) {
            icon?.image(size: Constants.iconSize)
                .accessibilityHidden(true)
            Text(title).storeTextStyle(.bodySmall).lineLimit(1)
        }
        .foregroundStyle(tone.appearance.foreground)
        .padding(.horizontal, StorePadding.p3)
        .frame(minHeight: Constants.minHeight)
        .background(tone.appearance.background ?? .clear)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.medium))
        .overlay {
            if let border = tone.appearance.border {
                RoundedRectangle(cornerRadius: StoreRadius.medium)
                    .strokeBorder(border, lineWidth: StoreStrokeWidth.medium)
            }
        }
    }
}

private extension StoreBadge {
    enum Constants {
        // Figma's 8pt top/bottom padding sits around cap-height-trimmed text (8+8+8 = 24).
        // SwiftUI's Text isn't cap-trimmed, so we hit that 24pt height via minHeight rather
        // than literal vertical padding (which would overshoot). Matches Android's heightIn(min: 24).
        static let minHeight: CGFloat = 24
        static let iconSize: StoreIconSize = .extraSmall
    }
}

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
        .frame(minHeight: StoreSize.badgeHeight)
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
        static let iconSize: StoreIconSize = .extraSmall
    }
}

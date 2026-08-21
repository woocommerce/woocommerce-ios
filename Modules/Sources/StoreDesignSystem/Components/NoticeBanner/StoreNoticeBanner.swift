import SwiftUI

public struct StoreNoticeBanner: View {
    private let title: String
    private let description: String?
    private let tone: StoreNoticeBannerTone
    private let icon: StoreIconImage?
    private let actionTitle: String?
    private let action: (() -> Void)?
    private let dismissAccessibilityLabel: String?
    private let onDismiss: (() -> Void)?

    public init(_ title: String,
                description: String? = nil,
                tone: StoreNoticeBannerTone = .neutral,
                icon: StoreIconImage? = nil,
                actionTitle: String? = nil,
                action: (() -> Void)? = nil,
                dismissAccessibilityLabel: String? = nil,
                onDismiss: (() -> Void)? = nil) {
        self.title = title
        self.description = description
        self.tone = tone
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
        self.dismissAccessibilityLabel = dismissAccessibilityLabel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack(alignment: .top, spacing: StoreSpacing.s4) {
            icon?.image(size: .large)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                Text(title).storeTextStyle(.bodyMedium.emphasized)
                if let description {
                    Text(description).storeTextStyle(.bodyMedium)
                }
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.plain)
                        .storeTextStyle(.bodyMedium.emphasized)
                        .underline()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                Button(action: onDismiss) {
                    StoreIcon.Xmark.regular.image(size: .medium)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(dismissAccessibilityLabel ?? Localization.dismissAccessibilityLabel)
            }
        }
        .padding(StorePadding.p6)
        .foregroundStyle(tone.appearance.foreground)
        .background(tone.appearance.background ?? .clear)
        .clipShape(RoundedRectangle(cornerRadius: StoreRadius.large))
        .overlay {
            if let border = tone.appearance.border {
                RoundedRectangle(cornerRadius: StoreRadius.large)
                    .strokeBorder(border, lineWidth: StoreStrokeWidth.regular)
            }
        }
        .accessibilityElement(children: action == nil && onDismiss == nil ? .combine : .contain)
    }
}
private enum Localization {
    static let dismissAccessibilityLabel = NSLocalizedString(
        "storeNoticeBanner.dismiss.accessibilityLabel",
        value: "Dismiss",
        comment: "Default accessibility label for dismissing a store notice banner."
    )
}

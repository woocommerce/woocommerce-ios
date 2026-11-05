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
    private let accessibility: StoreNoticeBannerAccessibility

    public init(_ title: String,
                description: String? = nil,
                tone: StoreNoticeBannerTone = .neutral,
                icon: StoreIconImage? = nil,
                actionTitle: String? = nil,
                action: (() -> Void)? = nil,
                dismissAccessibilityLabel: String? = nil,
                onDismiss: (() -> Void)? = nil,
                accessibilityStatus: String? = nil) {
        self.title = title
        self.description = description
        self.tone = tone
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
        self.dismissAccessibilityLabel = dismissAccessibilityLabel
        self.onDismiss = onDismiss
        self.accessibility = StoreNoticeBannerAccessibility(title: title,
                                                            description: description,
                                                            status: accessibilityStatus,
                                                            hasControls: action != nil || onDismiss != nil)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: StoreSpacing.s4) {
            icon?.image(size: .large)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                // One element that doesn't overlap the buttons, so VoiceOver touch focus can still reach them.
                VStack(alignment: .leading, spacing: StoreSpacing.s4) {
                    Text(title).storeTextStyle(.bodyMedium.emphasized)
                    if let description {
                        Text(description).storeTextStyle(.bodyMedium)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibility.label)
                .accessibilityValue(accessibility.status ?? "")
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .buttonStyle(.plain)
                        .storeTextStyle(.bodyMedium.emphasized)
                        .underline()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismiss {
                // The tap target overflows the icon's layout frame to the HIG minimum.
                Button(action: onDismiss) {
                    StoreIcon.Xmark.regular.image(size: .medium)
                        .frame(minWidth: StoreSize.minimumTapTarget, minHeight: StoreSize.minimumTapTarget)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: StoreIconSize.medium.value, height: StoreIconSize.medium.value)
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
        .accessibilityElement(children: accessibility.hasControls ? .contain : .combine)
    }
}

/// How VoiceOver reads a ``StoreNoticeBanner``.
///
/// Without controls the banner is one combined element. With an action or a dismiss button, the message (plus the
/// status, e.g. a severity) is one element and each control stays a separate, activatable element.
struct StoreNoticeBannerAccessibility: Equatable {
    let label: String
    let status: String?
    let hasControls: Bool

    init(title: String, description: String?, status: String?, hasControls: Bool) {
        self.label = [title, description].compactMap { $0 }.joined(separator: ", ")
        self.status = status
        self.hasControls = hasControls
    }
}
private enum Localization {
    static let dismissAccessibilityLabel = NSLocalizedString(
        "storeNoticeBanner.dismiss.accessibilityLabel",
        value: "Dismiss",
        comment: "Default accessibility label for dismissing a store notice banner."
    )
}

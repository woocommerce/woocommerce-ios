import Foundation
import SwiftUI

enum POSRefundModalLayout {
    static let horizontalPadding: CGFloat = 148
    static let cornerRadius: CGFloat = POSCornerRadiusStyle.extraLarge.value
    static let progressViewStyle = POSProgressViewStyle(size: 64, lineWidth: 20)
    static let fullScreenContentMaxWidth: CGFloat = 520
    static let fullScreenSummaryContentMaxWidth: CGFloat = 640
    static let fullScreenActionMaxWidth: CGFloat = 520
    static let fullScreenCompletionActionMaxWidth: CGFloat = 420

    /// Phone uses 0 horizontal padding so the modal can fill the narrow screen instead of
    /// shrinking the content to a thin strip with the iPad-tuned 148pt insets.
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : horizontalPadding
    }

    /// Phone presents the modal full-screen via `posModalFullScreen`, so the inner card
    /// should not be rounded (otherwise an inner-rounded card sits inside a square
    /// full-screen modal). On iPad the iPad-tuned corner radius is applied.
    static func cornerRadius(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : cornerRadius
    }
}

struct POSRefundNavigationHeader: View {
    let title: String?
    let backAction: (() -> Void)?
    let backAccessibilityLabel: String

    init(title: String? = nil,
         backAction: (() -> Void)?,
         backAccessibilityLabel: String) {
        self.title = title
        self.backAction = backAction
        self.backAccessibilityLabel = backAccessibilityLabel
    }

    var body: some View {
        HStack(alignment: horizontalSizeClass == .compact ? .center : .top, spacing: POSSpacing.medium) {
            if let backAction {
                POSPageHeaderBackButton(configuration: .init(state: .enabled, action: backAction))
                    .accessibilityLabel(backAccessibilityLabel)
            }

            if let title {
                Text(title)
                    .font(.posHeadingBold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    // Wraps rather than shrinking and then truncating, matching
                    // `POSPageHeaderView`. Translations run longer than the English the
                    // layout was sized for. The stack is top aligned, so the back button
                    // stays level with the first line.
                    .lineLimit(Constants.titleLineLimit)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: POSSpacing.none)
        }
        .foregroundColor(Color.posOnSurface)
        .frame(minHeight: horizontalSizeClass == .compact ? POSHeaderLayoutConstants.minHeight : nil)
        .padding(.horizontal, horizontalSizeClass == .compact ? POSHeaderLayoutConstants.sectionHorizontalPadding : POSPadding.xLarge)
        .padding(.top, horizontalSizeClass == .compact ? POSPadding.medium : POSPadding.xLarge)
        .padding(.bottom, horizontalSizeClass == .compact ? POSHeaderLayoutConstants.sectionVerticalPadding : POSPadding.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension POSRefundNavigationHeader {
    enum Constants {
        /// Two lines hold the longest translated refund headings on a phone without the
        /// header taking over the screen. Matches `POSPageHeaderView`.
        static let titleLineLimit: Int = 2
    }
}

enum POSRefundPresentationStyle {
    case modal
    case fullScreen
}

private struct POSRefundPresentationStyleKey: EnvironmentKey {
    static let defaultValue: POSRefundPresentationStyle = .modal
}

extension EnvironmentValues {
    var posRefundPresentationStyle: POSRefundPresentationStyle {
        get { self[POSRefundPresentationStyleKey.self] }
        set { self[POSRefundPresentationStyleKey.self] = newValue }
    }
}

/// Sizes a refund-flow modal: a centered, rounded card on iPad; an edge-to-edge full
/// screen take-over on phone. Matches the rest of the phone-prototype UI where modal
/// flows occupy the entire screen rather than appearing as a partial sheet.
struct POSRefundModalFrameModifier: ViewModifier {
    let parentSize: CGSize
    let horizontalSizeClass: UserInterfaceSizeClass?
    @Environment(\.posRefundPresentationStyle) private var presentationStyle

    func body(content: Content) -> some View {
        if presentationStyle == .fullScreen {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else if horizontalSizeClass == .compact {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            content
                .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
                .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding(for: horizontalSizeClass) * 2))
        }
    }
}

extension View {
    func posRefundModalFrame(parentSize: CGSize, horizontalSizeClass: UserInterfaceSizeClass?) -> some View {
        modifier(POSRefundModalFrameModifier(parentSize: parentSize, horizontalSizeClass: horizontalSizeClass))
    }
}

/// Refund actions share the horizontal and top padding of other compact POS actions.
/// They retain bottom padding inside the safe area; the cart measures its bottom inset separately.
/// Regular-width sheets keep their existing in-card padding.
struct POSPhoneFullScreenButtonPaddingModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let maxWidth: CGFloat
    @Environment(\.posRefundPresentationStyle) private var presentationStyle

    func body(content: Content) -> some View {
        if presentationStyle == .fullScreen {
            content
                .frame(maxWidth: .infinity)
                .frame(maxWidth: maxWidth)
                .if(horizontalSizeClass == .compact) {
                    $0.posPhoneBottomButtonPadding()
                }
                .if(horizontalSizeClass != .compact) {
                    $0
                        .padding(.horizontal, POSPadding.medium)
                        .padding(.top, POSPadding.medium)
                        .padding(.bottom, POSPadding.medium)
                }
                .frame(maxWidth: .infinity)
        } else if horizontalSizeClass == .compact {
            content
                .posPhoneBottomButtonPadding()
        } else {
            content
                .padding(POSPadding.xLarge)
        }
    }
}

extension View {
    func posPhoneFullScreenButtonPadding(horizontalSizeClass: UserInterfaceSizeClass?,
                                         maxWidth: CGFloat = POSRefundModalLayout.fullScreenActionMaxWidth) -> some View {
        modifier(POSPhoneFullScreenButtonPaddingModifier(horizontalSizeClass: horizontalSizeClass,
                                                         maxWidth: maxWidth))
    }
}

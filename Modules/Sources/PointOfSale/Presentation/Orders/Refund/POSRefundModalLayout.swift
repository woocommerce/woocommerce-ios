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

    /// Compact layout uses 0 horizontal padding so the modal can fill the narrow screen instead of
    /// shrinking the content to a thin strip with the regular-layout 148pt insets.
    static func horizontalPadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : horizontalPadding
    }

    /// Compact layout presents the modal full-screen via `posModalFullScreen`, so the inner card
    /// should not be rounded (otherwise an inner-rounded card sits inside a square
    /// full-screen modal). In regular layout the regular corner radius is applied.
    static func cornerRadius(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        sizeClass == .compact ? 0 : cornerRadius
    }
}

struct POSRefundNavigationHeader: View {
    let title: String?
    let backAction: (() -> Void)?
    let backAccessibilityLabel: String

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(title: String? = nil,
         backAction: (() -> Void)?,
         backAccessibilityLabel: String) {
        self.title = title
        self.backAction = backAction
        self.backAccessibilityLabel = backAccessibilityLabel
    }

    var body: some View {
        HStack(alignment: .top, spacing: POSSpacing.medium) {
            if let backAction {
                POSPageHeaderBackButton(configuration: .init(state: .enabled, action: backAction))
                    .accessibilityLabel(backAccessibilityLabel)
            }

            if let title {
                Text(title)
                    .font(.posHeadingBold)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .lineLimit(1)
                    .minimumScaleFactor(horizontalSizeClass == .compact ? 0.7 : 1.0)
            }

            Spacer(minLength: POSSpacing.none)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
        .frame(maxWidth: .infinity, alignment: .leading)
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

/// Sizes a refund-flow modal: a centered, rounded card in regular layout; an edge-to-edge full
/// screen take-over in compact layout. Matches the rest of the compact UI where modal
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

/// Standardizes the bottom-anchored action buttons across compact POS so refund / totals /
/// cart all share the same horizontal insets and home-indicator clearance as the compact cart
/// button. Regular layout keeps the existing in-card padding so the centered modal still breathes.
struct POSCompactFullScreenButtonPaddingModifier: ViewModifier {
    let horizontalSizeClass: UserInterfaceSizeClass?
    let maxWidth: CGFloat
    @Environment(\.posRefundPresentationStyle) private var presentationStyle

    func body(content: Content) -> some View {
        if presentationStyle == .fullScreen {
            content
                .frame(maxWidth: .infinity)
                .frame(maxWidth: maxWidth)
                .if(horizontalSizeClass == .compact) {
                    $0.posCompactBottomButtonPadding()
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
                .posCompactBottomButtonPadding()
        } else {
            content
                .padding(POSPadding.xLarge)
        }
    }
}

extension View {
    func posCompactFullScreenButtonPadding(horizontalSizeClass: UserInterfaceSizeClass?,
                                         maxWidth: CGFloat = POSRefundModalLayout.fullScreenActionMaxWidth) -> some View {
        modifier(POSCompactFullScreenButtonPaddingModifier(horizontalSizeClass: horizontalSizeClass,
                                                         maxWidth: maxWidth))
    }
}

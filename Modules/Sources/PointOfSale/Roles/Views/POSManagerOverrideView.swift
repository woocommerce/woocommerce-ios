import SwiftUI

struct POSManagerOverrideView: View {
    @Environment(\.posMetrics) private var metrics
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posModalParentSize) private var parentSize

    let handler: POSManagerOverrideHandler
    let request: POSManagerOverrideRequest

    var body: some View {
        ViewThatFits(in: .vertical) {
            Group {
                if isCompactWidth { compactContent } else { modalContent }
            }
            scrollingContent
        }
        .frame(maxHeight: max(0, parentSize.height - verticalInsets))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

private extension POSManagerOverrideView {
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var verticalInsets: CGFloat {
        isCompactWidth ? 0 : 2 * (metrics.padding.xxLarge + metrics.padding.medium)
    }

    var scrollingContent: some View {
        VStack(spacing: metrics.spacing.large) {
            POSModalCloseButton(accessibilityLabel: Localization.close, closeAction: { handler.cancel() })
            ScrollView {
                VStack(spacing: metrics.spacing.large) {
                    header(spacing: isCompactWidth ? metrics.spacing.small : metrics.spacing.medium)
                    pinEntry
                }
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: POSPINEntryView.contentWidth)
        .padding(isCompactWidth ? metrics.padding.large : metrics.padding.none)
    }

    var modalContent: some View {
        VStack(spacing: metrics.spacing.large) {
            header(spacing: metrics.spacing.medium)

            pinEntry
        }
        .frame(maxWidth: POSPINEntryView.contentWidth)
        .padding(.top, metrics.padding.large)
        .posModalCloseButton(action: { handler.cancel() }, accessibilityLabel: Localization.close)
        .fixedSize(horizontal: false, vertical: true)
    }

    var compactContent: some View {
        VStack(spacing: metrics.spacing.large) {
            header(spacing: metrics.spacing.small)

            pinEntry
        }
        .frame(maxWidth: POSPINEntryView.contentWidth)
        .padding(.horizontal, metrics.padding.large)
        .posModalCloseButton(action: { handler.cancel() }, accessibilityLabel: Localization.close)
        .padding(metrics.padding.large)
        // Size to content and let the modal center it, like the lock screen and the iPad layout. Filling
        // the screen pushed the close button under the status bar (status-bar overlap, untappable).
        .fixedSize(horizontal: false, vertical: true)
    }

    func header(spacing: CGFloat) -> some View {
        VStack(spacing: spacing) {
            title
            reason
        }
    }

    var title: some View {
        Text(Localization.title)
            .font(.posHeadingBold)
            .foregroundStyle(Color.posOnSurface)
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(Constants.titleMinimumScaleFactor)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    var reason: some View {
        Text(request.reason)
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurfaceVariantHighest)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(Constants.compactReasonMinimumScaleFactor)
            .fixedSize(horizontal: false, vertical: true)
    }

    var pinEntry: some View {
        POSPINEntryView(state: handler.pinEntryState) { pin in
            await handler.submit(pin: pin)
        }
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.managerOverride.approvalRequired.title",
            value: "Approval required",
            comment: "Title shown on the POS manager approval modal."
        )
        static let close = NSLocalizedString(
            "pos.managerOverride.close",
            value: "Close",
            comment: "Accessibility label for dismissing the POS manager approval screen."
        )
    }

    enum Constants {
        static let titleMinimumScaleFactor: CGFloat = 0.75
        static let compactReasonMinimumScaleFactor: CGFloat = 0.9
    }
}

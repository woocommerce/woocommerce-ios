import SwiftUI

struct POSManagerOverrideView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let handler: POSManagerOverrideHandler
    let request: POSManagerOverrideRequest

    var body: some View {
        Group {
            if isCompactWidth {
                compactContent
            } else {
                modalContent
            }
        }
        .dynamicTypeSize(.large)
    }
}

private extension POSManagerOverrideView {
    var isCompactWidth: Bool {
        horizontalSizeClass == .compact
    }

    var modalContent: some View {
        VStack(spacing: POSPINEntryView.titleToPINSpacing) {
            header(spacing: POSSpacing.medium)

            pinEntry
                .frame(height: POSPINEntryView.preferredHeight)
        }
        .frame(maxWidth: POSPINEntryView.contentWidth)
        .padding(.top, Constants.modalTopInset)
        .posModalCloseButton(action: { handler.cancel() }, accessibilityLabel: Localization.close)
        .fixedSize(horizontal: false, vertical: true)
    }

    var compactContent: some View {
        VStack(spacing: POSPINEntryView.titleToPINSpacing) {
            header(spacing: POSSpacing.small)

            pinEntry
                .frame(height: POSPINEntryView.preferredHeight)
        }
        .frame(maxWidth: POSPINEntryView.contentWidth)
        .padding(.horizontal, POSPadding.large)
        .posModalCloseButton(action: { handler.cancel() }, accessibilityLabel: Localization.close)
        .padding(POSPadding.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            Task {
                await handler.submit(pin: pin)
            }
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
        static let modalTopInset: CGFloat = POSPadding.large
    }
}

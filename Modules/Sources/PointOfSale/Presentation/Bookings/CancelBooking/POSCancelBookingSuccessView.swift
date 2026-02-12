import SwiftUI

struct POSCancelBookingSuccessView: View {
    let onDone: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            contentView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isViewLoaded = true
            }
        }
    }
}

// MARK: - Subviews

private extension POSCancelBookingSuccessView {
    var headerView: some View {
        HStack {
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var contentView: some View {
        VStack(spacing: POSSpacing.xLarge) {
            POSSuccessIcon()
                .scaleEffect(isViewLoaded ? 1 : 0)
                .opacity(isViewLoaded ? 1 : 0)

            VStack(spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                Text(Localization.message)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, POSPadding.xLarge)
        .padding(.bottom, POSSpacing.xLarge)
    }

    var buttonsSection: some View {
        Button(Localization.doneButton, action: onDone)
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .padding(POSPadding.xLarge)
            .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
            .opacity(isViewLoaded ? 1 : 0)
    }
}

// MARK: - Constants

private extension POSCancelBookingSuccessView {
    enum Constants {
        static let animationOffset: CGFloat = 100
    }
}

// MARK: - Localization

private extension POSCancelBookingSuccessView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.cancelBookingSuccess.title",
            value: "Booking cancelled",
            comment: "Title shown when a booking has been successfully cancelled in POS."
        )

        static let message = NSLocalizedString(
            "pos.cancelBookingSuccess.message",
            value: "The booking has been successfully cancelled.",
            comment: "Message shown after a booking is successfully cancelled in POS."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.cancelBookingSuccess.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on cancel booking success screen."
        )

        static let doneButton = NSLocalizedString(
            "pos.cancelBookingSuccess.doneButton",
            value: "Done",
            comment: "Button to dismiss the cancel booking success screen in POS."
        )
    }
}

#if DEBUG
#Preview("POSCancelBookingSuccessView") {
    POSCancelBookingSuccessView(
        onDone: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif

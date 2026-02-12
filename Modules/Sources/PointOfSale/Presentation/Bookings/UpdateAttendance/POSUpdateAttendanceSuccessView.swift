import SwiftUI

struct POSUpdateAttendanceSuccessView: View {
    let targetStatus: POSBookingAttendanceDisplay
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

private extension POSUpdateAttendanceSuccessView {
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

                Text(successMessage)
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

    private var successMessage: String {
        switch targetStatus {
        case .attended:
            return Localization.markedAttendedMessage
        case .unattended:
            return Localization.markedUnattendedMessage
        }
    }
}

// MARK: - Constants

private extension POSUpdateAttendanceSuccessView {
    enum Constants {
        static let animationOffset: CGFloat = 100
    }
}

// MARK: - Localization

private extension POSUpdateAttendanceSuccessView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.updateAttendanceSuccess.title",
            value: "Attendance updated",
            comment: "Title shown when attendance status has been successfully updated in POS."
        )

        static let markedAttendedMessage = NSLocalizedString(
            "pos.updateAttendanceSuccess.markedAttendedMessage",
            value: "The booking has been marked as attended.",
            comment: "Message shown after a booking is successfully marked as attended in POS."
        )

        static let markedUnattendedMessage = NSLocalizedString(
            "pos.updateAttendanceSuccess.markedUnattendedMessage",
            value: "The booking has been marked as unattended.",
            comment: "Message shown after a booking is successfully marked as unattended in POS."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.updateAttendanceSuccess.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on update attendance success screen."
        )

        static let doneButton = NSLocalizedString(
            "pos.updateAttendanceSuccess.doneButton",
            value: "Done",
            comment: "Button to dismiss the update attendance success screen in POS."
        )
    }
}

#if DEBUG
#Preview("Marked Attended") {
    POSUpdateAttendanceSuccessView(
        targetStatus: .attended,
        onDone: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("Marked Unattended") {
    POSUpdateAttendanceSuccessView(
        targetStatus: .unattended,
        onDone: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif

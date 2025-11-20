import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            HStack {
                Spacer()
                Button {
                    isPresented = false
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(.posButtonSymbolLarge)
                }
                .accessibilityIdentifier("pos-exit-modal-close-button")
                .foregroundColor(Color.posOnSurfaceVariantLowest)
            }
            Text(Localization.exitTitle)
                .font(.posHeadingBold)
                .foregroundColor(Color.posOnSurface)
            Text(Localization.exitBody)
                .font(.posBodyLargeRegular())
                .foregroundColor(Color.posOnSurface)
            Button {
                analytics.track(.pointOfSaleExitConfirmed)
                dismiss()
            } label: {
                Text(Localization.exitButton)
            }
            .accessibilityIdentifier("pos-exit-confirm-button")
            .buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .padding(Constants.padding)
    }
}

private extension PointOfSaleExitPosAlertView {
    enum Constants {
        static let verticalSpacing: CGFloat = POSSpacing.xLarge
        static let padding: CGFloat = POSPadding.medium
    }

    enum Localization {
        static let exitTitle = NSLocalizedString(
            "pos.exitPOSModal.exitTitle",
            value: "Exit Point of Sale mode?",
            comment: "Title of the exit Point of Sale modal alert"
        )
        static let exitBody = NSLocalizedString(
            "pos.exitPOSModal.exitBody",
            value: "Any orders in progress will be lost.",
            comment: "Body text of the exit Point of Sale modal alert"
        )
        static let exitButton = NSLocalizedString(
            "pos.exitPOSModal.exitButtom",
            value: "Exit",
            comment: "Button text of the exit Point of Sale modal alert"
        )
    }
}

#if DEBUG
#Preview {
    PointOfSaleExitPosAlertView(isPresented: .constant(true))
}
#endif

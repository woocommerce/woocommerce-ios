import SwiftUI

struct PointOfSaleExitPosAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding private var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        if horizontalSizeClass == .compact {
            compactBody
        } else {
            regularBody
        }
    }

    private var regularBody: some View {
        VStack(spacing: Constants.verticalSpacing) {
            regularCloseButton
            content
        }
        .padding(Constants.padding)
    }

    private var compactBody: some View {
        VStack(spacing: POSSpacing.none) {
            compactCloseButton

            Spacer(minLength: POSSpacing.none)

            content

            Spacer(minLength: POSSpacing.none)
        }
        .padding(POSPadding.xLarge)
        .background(Color.posSurfaceBright)
        .frame(width: parentSize.width, height: parentSize.height, alignment: .top)
    }

    private var regularCloseButton: some View {
        HStack {
            Spacer()
            closeButton
                .font(.posButtonSymbolLarge)
                .foregroundColor(Color.posOnSurfaceVariantLowest)
        }
    }

    private var compactCloseButton: some View {
        HStack {
            Spacer()
            closeButton
                .font(.posButtonSymbolMedium)
                .foregroundColor(Color.posOnSurface)
                .accessibilitySortPriority(-1)
        }
    }

    private var closeButton: some View {
        Button {
            isPresented = false
        } label: {
            Text(Image(systemName: "xmark"))
        }
        .accessibilityIdentifier("pos-exit-modal-close-button")
        .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
    }

    private var content: some View {
        VStack(spacing: Constants.verticalSpacing) {
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
        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.exitPOSModal.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for the button to close the exit Point of Sale modal alert."
        )
    }
}

#if DEBUG
#Preview {
    PointOfSaleExitPosAlertView(isPresented: .constant(true))
}
#endif

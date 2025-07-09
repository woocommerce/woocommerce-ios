import SwiftUI

// MARK: - Flow Buttons View
@available(iOS 17.0, *)
struct FlowButtonsView: View {
    let buttonConfiguration: ButtonConfiguration

    var body: some View {
        HStack(spacing: POSSpacing.medium) {
            if buttonConfiguration.shouldShowBackButton {
                Button(Localization.backButtonTitle) {
                    buttonConfiguration.onBack()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
            }
            if buttonConfiguration.shouldShowNextButton {
                Button(buttonConfiguration.nextButtonTitle) {
                    buttonConfiguration.onNext()
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!buttonConfiguration.isNextButtonEnabled)
            }
        }
    }
}

// MARK: - Scanner Selection View
struct ScannerSelectionView: View {
    let options: [ScannerOption]
    let onSelection: (ScannerType) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.setupIntroMessage)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: POSSpacing.small) {
                ForEach(options) { option in
                    Button {
                        onSelection(option.scannerType)
                    } label: {
                        ScannerOptionView(
                            title: option.title,
                            subtitle: option.subtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: - Scanner Option View
struct ScannerOptionView: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                Text(title)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posOnSurface)
                Text(subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.posBodyMediumBold)
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceDim)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
    }
}

// MARK: - Step Views
struct ScannerWelcomeView: View {
    let title: String

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            Text(title)
                .font(.posBodyLargeBold)
                .foregroundColor(.posOnSurface)

            Text("TODO: Implement \(title) setup flow")
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Private Localization Extensions

@available(iOS 17.0, *)
private extension FlowButtonsView {
    enum Localization {
        static let backButtonTitle = NSLocalizedString(
            "pos.barcodeScannerSetup.back.button.title",
            value: "Back",
            comment: "Title for the back button in barcode scanner setup navigation"
        )
    }
}

private extension ScannerSelectionView {
    enum Localization {
        static let setupIntroMessage = NSLocalizedString(
            "pos.barcodeScannerSetup.introMessage",
            value: "Choose your barcode scanner to get started with the setup process.",
            comment: "Introductory message in the barcode scanner setup flow in POS"
        )
    }
}

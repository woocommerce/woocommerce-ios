import SwiftUI

struct PointOfSaleBarcodeScannerSetUpFlow: View {
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        NavigationStack {
            ScannerSelectionView(isPresented: $isPresented)
        }
        .onAppear {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
    }
}

struct ScannerSelectionView: View {
    @Binding var isPresented: Bool

    var body: some View {
        PointOfSaleInformationModal(isPresented: $isPresented, title: AttributedString(Localization.setupHeading)) {
            VStack(spacing: POSSpacing.medium) {
                Text(AttributedString(Localization.setupIntroMessage))
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: POSSpacing.small) {
                    // Socket S720
                    NavigationLink(destination: EmptyView()) {
                        ScannerOptionView(
                            title: Localization.socketS720Title,
                            subtitle: Localization.socketS720Subtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Star BSH-20B
                    NavigationLink(destination: EmptyView()) {
                        ScannerOptionView(
                            title: Localization.starBSH20BTitle,
                            subtitle: Localization.starBSH20BSubtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // TBC Scanner
                    NavigationLink(destination: EmptyView()) {
                        ScannerOptionView(
                            title: Localization.tbcScannerTitle,
                            subtitle: Localization.tbcScannerSubtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    // Other
                    NavigationLink(destination: BarcodeScannerInformationView()) {
                        ScannerOptionView(
                            title: Localization.otherTitle,
                            subtitle: Localization.otherSubtitle
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

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
            Image(systemName: "chevron.right")
                .font(.posBodyMediumBold)
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceDim)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
    }
}

struct BarcodeScannerInformationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PointOfSaleBarcodeScannerInformationModal(isPresented: .constant(true))
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: POSSpacing.xSmall) {
                        Image(systemName: "chevron.left")
                            .font(.posBodyMediumBold)
                        Text(Localization.backButtonTitle)
                            .font(.posBodyMediumBold)
                    }
                    .foregroundColor(.posOnSurface)
                }
            }
        }
    }
}

// MARK: - Localization
private enum Localization {
    static let setupHeading = NSLocalizedString(
        "pos.barcodeScannerSetup.heading",
        value: "Barcode Scanner Setup",
        comment: "Heading for the barcode scanner setup flow in POS"
    )
    static let setupIntroMessage = NSLocalizedString(
        "pos.barcodeScannerSetup.introMessage",
        value: "Choose your barcode scanner to get started with the setup process.",
        comment: "Introductory message in the barcode scanner setup flow in POS"
    )
    static let socketS720Title = NSLocalizedString(
        "pos.barcodeScannerSetup.socketS720.title",
        value: "Socket S720",
        comment: "Title for Socket S720 scanner option in barcode scanner setup"
    )
    static let socketS720Subtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.socketS720.subtitle",
        value: "Recommended scanner",
        comment: "Subtitle for Socket S720 scanner option in barcode scanner setup"
    )
    static let starBSH20BTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.title",
        value: "Star BSH-20B",
        comment: "Title for Star BSH-20B scanner option in barcode scanner setup"
    )
    static let starBSH20BSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.subtitle",
        value: "Recommended scanner",
        comment: "Subtitle for Star BSH-20B scanner option in barcode scanner setup"
    )
    static let tbcScannerTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.tbcScanner.title",
        value: "Scanner TBC",
        comment: "Title for TBC scanner option in barcode scanner setup"
    )
    static let tbcScannerSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.tbcScanner.subtitle",
        value: "Recommended scanner",
        comment: "Subtitle for TBC scanner option in barcode scanner setup"
    )
    static let otherTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.other.title",
        value: "Other",
        comment: "Title for other scanner option in barcode scanner setup"
    )
    static let otherSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.other.subtitle",
        value: "General setup instructions",
        comment: "Subtitle for other scanner option in barcode scanner setup"
    )
    static let backButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.back.button.title",
        value: "Back",
        comment: "Title for the back button in barcode scanner setup navigation"
    )
}

#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}

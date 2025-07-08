import SwiftUI

// MARK: - Data Models
struct ScannerOption: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let destination: SetupDestination
}

enum SetupDestination {
    case socketS720
    case starBSH20B
    case tbcScanner
    case other
}

@available(iOS 17.0, *)
struct PointOfSaleBarcodeScannerSetUpFlow: View {
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.xxLarge) {
                PointOfSaleModalHeader(isPresented: $isPresented,
                                       title: .constant(AttributedString(Localization.setupHeading)))

                VStack {
                    ScannerSelectionView(options: scannerOptions, isPresented: $isPresented)
                    Spacer()
                }
                .scrollVerticallyIfNeeded()
            }
            .toolbar(.hidden, for: .navigationBar)
            .padding(POSPadding.xxLarge)
        }
        .background(Color.posSurfaceBright)
        .containerRelativeFrame([.horizontal, .vertical]) { length, _ in
            max(length * 0.75, Constants.modalFrameMaxSmallDimension)
        }
        .onAppear {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        }
    }

    private var scannerOptions: [ScannerOption] {
        [
            ScannerOption(
                title: Localization.socketS720Title,
                subtitle: Localization.socketS720Subtitle,
                destination: .socketS720
            ),
            ScannerOption(
                title: Localization.starBSH20BTitle,
                subtitle: Localization.starBSH20BSubtitle,
                destination: .starBSH20B
            ),
            ScannerOption(
                title: Localization.tbcScannerTitle,
                subtitle: Localization.tbcScannerSubtitle,
                destination: .tbcScanner
            ),
            ScannerOption(
                title: Localization.otherTitle,
                subtitle: Localization.otherSubtitle,
                destination: .other
            )
        ]
    }
}

struct ScannerSelectionView: View {
    let options: [ScannerOption]
    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.setupIntroMessage)
                .font(.posBodyLargeRegular())
                .foregroundStyle(Color.posOnSurface)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: POSSpacing.small) {
                ForEach(options) { option in
                    NavigationLink(destination: destinationView(for: option.destination)) {
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

    @ViewBuilder
    private func destinationView(for destination: SetupDestination) -> some View {
        switch destination {
        case .socketS720:
            EmptyView() // TODO: Implement Socket S720 setup flow WOOMOB-698
        case .starBSH20B:
            EmptyView() // TODO: Implement Star BSH-20B setup flow WOOMOB-696
        case .tbcScanner:
            EmptyView() // TODO: Implement TBC scanner setup flow WOOMOB-699
        case .other:
            BarcodeScannerInformationView(isPresented: $isPresented)
                .padding(POSPadding.xxLarge)
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
            Image(systemName: "chevron.forward")
                .font(.posBodyMediumBold)
                .foregroundColor(.posOnSurfaceVariantHighest)
        }
        .padding(POSPadding.medium)
        .background(Color.posSurfaceDim)
        .clipShape(RoundedRectangle(cornerRadius: POSCornerRadiusStyle.medium.value))
    }
}

struct BarcodeScannerInformationView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            PointOfSaleModalHeader(isPresented: $isPresented,
                                   title: .constant(AttributedString(PointOfSaleBarcodeScannerInformationModal.Localization.barcodeInfoHeading)))
            VStack {
                BarcodeScannerInformationContent()
                Spacer()
            }
            .scrollVerticallyIfNeeded()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}


private enum Constants {
    static var modalFrameMaxSmallDimension: CGFloat { 752 }
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
        value: "Small handheld scanner with a charging dock or stand",
        comment: "Subtitle for Socket S720 scanner option in barcode scanner setup"
    )
    static let starBSH20BTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.title",
        value: "Star BSH-20B",
        comment: "Title for Star BSH-20B scanner option in barcode scanner setup"
    )
    static let starBSH20BSubtitle = NSLocalizedString(
        "pos.barcodeScannerSetup.starBSH20B.subtitle",
        value: "Ergonomic scanner with a stand",
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
        value: "General scanner setup instructions",
        comment: "Subtitle for other scanner option in barcode scanner setup"
    )
    static let backButtonTitle = NSLocalizedString(
        "pos.barcodeScannerSetup.back.button.title",
        value: "Back",
        comment: "Title for the back button in barcode scanner setup navigation"
    )
}

@available(iOS 17.0, *)
#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}

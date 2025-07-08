import SwiftUI

struct PointOfSaleBarcodeScannerSetUpFlow: View {
    @Binding var isPresented: Bool
    @State private var showingInformationModal = false

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

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
                    Button(action: {
                        // TODO: Navigate to Socket S720 setup flow
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                                Text(Localization.socketS720Title)
                                    .font(.posBodyLargeBold)
                                    .foregroundColor(.posOnSurface)
                                Text(Localization.socketS720Subtitle)
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
                    .buttonStyle(PlainButtonStyle())

                    // Star BSH-20B
                    Button(action: {
                        // TODO: Navigate to Star BSH-20B setup flow
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                                Text(Localization.starBSH20BTitle)
                                    .font(.posBodyLargeBold)
                                    .foregroundColor(.posOnSurface)
                                Text(Localization.starBSH20BSubtitle)
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
                    .buttonStyle(PlainButtonStyle())

                    // TBC Scanner
                    Button(action: {
                        // TODO: Navigate to TBC scanner setup flow
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                                Text(Localization.tbcScannerTitle)
                                    .font(.posBodyLargeBold)
                                    .foregroundColor(.posOnSurface)
                                Text(Localization.tbcScannerSubtitle)
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
                    .buttonStyle(PlainButtonStyle())

                    // Other
                    Button(action: {
                        showingInformationModal = true
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                                Text(Localization.otherTitle)
                                    .font(.posBodyLargeBold)
                                    .foregroundColor(.posOnSurface)
                                Text(Localization.otherSubtitle)
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
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .sheet(isPresented: $showingInformationModal) {
            PointOfSaleBarcodeScannerInformationModal(isPresented: $showingInformationModal)
        }
        .onAppear(perform: {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScannerSetupFlowShown)
        })
    }
}

private extension PointOfSaleBarcodeScannerSetUpFlow {
    enum Localization {
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
    }
}

#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}

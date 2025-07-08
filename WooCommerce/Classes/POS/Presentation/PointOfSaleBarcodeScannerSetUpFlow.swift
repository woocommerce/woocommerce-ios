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
                    NavigationLink(destination: EmptyView()) {
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
                    NavigationLink(destination: EmptyView()) {
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
                    NavigationLink(destination: BarcodeScannerInformationView()) {
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
    }
}

struct BarcodeScannerInformationView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PointOfSaleInformationModal(isPresented: .constant(true), title: AttributedString(Localization.barcodeInfoHeading)) {
            PointOfSaleInformationModalParagraphView {
                Text(AttributedString(Localization.barcodeInfoIntroMessage))
            }

            PointOfSaleInformationModalParagraphView {
                Text(bulletPointWithLink)
                    .accessibilityLabel(bulletPointWithLinkAccessibilityLabel)
                Text(AttributedString(Localization.barcodeInfoSecondaryMessage))
                    .accessibilityLabel(Localization.barcodeInfoSecondaryMessageAccessible)
                Text(AttributedString(Localization.barcodeInfoTertiaryMessage))
                    .accessibilityLabel(Localization.barcodeInfoTertiaryMessageAccessible)
                Text(AttributedString(Localization.barcodeInfoQuaternaryMessage))
                    .accessibilityLabel(Localization.barcodeInfoQuaternaryMessageAccessible)
            }
            .padding(.leading, POSSpacing.medium)

            PointOfSaleInformationModalParagraphView(style: .outlined) {
                Text(AttributedString(Localization.barcodeInfoQuinaryMessage))
            }
        }
        .onAppear(perform: {
            ServiceLocator.analytics.track(.pointOfSaleBarcodeScanningExplanationDialogShown)
        })
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

    private var bulletPointWithLink: AttributedString {
        var secondary = AttributedString(Localization.barcodeInfoPrimaryMessage + " ")
        var moreDetails = AttributedString(Localization.barcodeInfoMoreDetailsLink)
        moreDetails.link = Constants.detailsLink
        moreDetails.foregroundColor = .posPrimary
        moreDetails.underlineStyle = .single
        secondary.append(moreDetails)
        return secondary
    }

    private var bulletPointWithLinkAccessibilityLabel: String {
        return Localization.barcodeInfoPrimaryMessageAccessible + " " + Localization.barcodeInfoMoreDetailsLinkAccessible
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

    // Barcode info localization (reused from existing modal)
    static let barcodeInfoHeading = NSLocalizedString(
        "pos.barcodeInfoModal.heading",
        value: "Barcode scanning",
        comment: "Heading for the barcode info modal in POS, introducing barcode scanning feature"
    )
    static let barcodeInfoIntroMessage = NSLocalizedString(
        "pos.barcodeInfoModal.introMessage",
        value: "You can scan barcodes using an external scanner to quickly build a cart.",
        comment: "Introductory message in the barcode info modal in POS, explaining the use of external barcode scanners"
    )
    static let barcodeInfoPrimaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.primaryMessage",
        value: "• Set up barcodes in the \"GTIN, UPC, EAN, ISBN\" field in Products > Product Details > Inventory. ",
        comment: "Primary bullet point in the barcode info modal in POS, instructing where to set up barcodes in product details"
    )
    static let barcodeInfoMoreDetailsLink = NSLocalizedString(
        "pos.barcodeInfoModal.moreDetailsLink",
        value: "More details.",
        comment: "Link text in the barcode info modal in POS, leading to more details about barcode setup"
    )
    static let barcodeInfoMoreDetailsLinkAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.moreDetailsLink.accessible",
        value: "More details, link.",
        comment: "Accessible version of more details link in barcode info modal, announcing it as a link for screen readers"
    )
    static let barcodeInfoSecondaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.secondaryMessage.2",
        value: "• Refer to your Bluetooth barcode scanner's instructions to set HID mode. This usually " +
        "requires scanning a special barcode in the manual.",
        comment: "Secondary bullet point in the barcode info modal in POS, instructing to set scanner to HID mode"
    )
    static let barcodeInfoTertiaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.tertiaryMessage",
        value: "• Connect your barcode scanner in iOS Bluetooth settings.",
        comment: "Tertiary bullet point in the barcode info modal in POS, instructing to connect scanner via Bluetooth settings"
    )
    static let barcodeInfoQuaternaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.quaternaryMessage",
        value: "• Scan barcodes while on the item list to add products to the cart.",
        comment: "Quaternary bullet point in the barcode info modal in POS, instructing to scan barcodes on item list to add to cart"
    )
    static let barcodeInfoQuinaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.quinaryMessage",
        value: "The scanner emulates a keyboard, so sometimes it will prevent the software keyboard from showing, e.g. in search. " +
            "Tap on the keyboard icon to show it again.",
        comment: "Quinary message in the barcode info modal in POS, explaining scanner keyboard emulation and how to show software keyboard again"
    )

    // Accessibility-friendly versions without bullet points
    static let barcodeInfoPrimaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.primaryMessage.accessible",
        value: "First: Set up barcodes in the \"G-T-I-N, U-P-C, E-A-N, I-S-B-N\" field by navigating to Products, then Product Details, then Inventory.",
        comment: "Accessible version of primary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let barcodeInfoSecondaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.secondaryMessage.accessible.2",
        value: "Second: Refer to your Bluetooth barcode scanner's instructions to set H-I-D mode. This usually " +
        "requires scanning a special barcode in the manual.",
        comment: "Accessible version of secondary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let barcodeInfoTertiaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.tertiaryMessage.accessible",
        value: "Third: Connect your barcode scanner in iOS Bluetooth settings.",
        comment: "Accessible version of tertiary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let barcodeInfoQuaternaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.quaternaryMessage.accessible",
        value: "Fourth: Scan barcodes while on the item list to add products to the cart.",
        comment: "Accessible version of quaternary bullet point in barcode info modal, without bullet character for screen readers"
    )
}

private enum Constants {
    static let detailsLink = URL(string: "https://woocommerce.com/document/barcode-and-qr-code-scanner/")
}


#Preview {
    PointOfSaleBarcodeScannerSetUpFlow(isPresented: .constant(true))
}

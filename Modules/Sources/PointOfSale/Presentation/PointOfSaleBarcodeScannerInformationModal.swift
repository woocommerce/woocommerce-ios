import Foundation
import SwiftUI

struct PointOfSaleBarcodeScannerInformationModal: View {
    @Binding var isPresented: Bool

    init(isPresented: Binding<Bool>) {
        self._isPresented = isPresented
    }

    var body: some View {
        PointOfSaleInformationModal(isPresented: $isPresented, title: AttributedString(Localization.barcodeInfoHeading)) {
            LegacyBarcodeScannerInformationContent()
        }
    }
}

struct LegacyBarcodeScannerInformationContent: View {
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            PointOfSaleInformationModalParagraphView {
                Text(AttributedString(Localization.legacyBarcodeInfoIntroMessage))
            }

            PointOfSaleInformationModalParagraphView {
                Text(bulletPointWithLink)
                    .accessibilityLabel(bulletPointWithLinkAccessibilityLabel)
                Text(AttributedString(Localization.legacyBarcodeInfoSecondaryMessage))
                    .accessibilityLabel(Localization.legacyBarcodeInfoSecondaryMessageAccessible)
                Text(AttributedString(Localization.legacyBarcodeInfoTertiaryMessage))
                    .accessibilityLabel(Localization.legacyBarcodeInfoTertiaryMessageAccessible)
                Text(AttributedString(Localization.legacyBarcodeInfoQuaternaryMessage))
                    .accessibilityLabel(Localization.legacyBarcodeInfoQuaternaryMessageAccessible)
            }
            .padding(.leading, POSSpacing.medium)

            PointOfSaleInformationModalParagraphView(style: .outlined) {
                Text(AttributedString(Localization.legacyBarcodeInfoQuinaryMessage))
            }
        }
        .onAppear(perform: {
            analytics.track(.pointOfSaleBarcodeScanningExplanationDialogShown)
        })
    }

    private var bulletPointWithLink: AttributedString {
        var secondary = AttributedString(Localization.legacyBarcodeInfoPrimaryMessage + " ")
        var moreDetails = AttributedString(Localization.legacyBarcodeInfoMoreDetailsLink)
        moreDetails.link = Constants.detailsLink
        moreDetails.foregroundColor = .posPrimary
        moreDetails.underlineStyle = .single
        secondary.append(moreDetails)
        return secondary
    }

    private var bulletPointWithLinkAccessibilityLabel: String {
        return Localization.legacyBarcodeInfoPrimaryMessageAccessible + " " + Localization.legacyBarcodeInfoMoreDetailsLinkAccessible
    }
}

struct BarcodeScannerInformation: View {
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Text(Localization.scannerInfoHeading)
                .font(.posHeadingBold)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.xLarge) {
                PointOfSaleInformationModalParagraphView {
                    Text(AttributedString(Localization.barcodeInfoIntroMessage))
                }

                PointOfSaleInformationModalParagraphView {
                    Text(AttributedString(Localization.barcodeInfoBluetoothMessage))
                        .accessibilityLabel(Localization.barcodeInfoBluetoothMessageAccessible)
                    Text(AttributedString(Localization.barcodeInfoScanMessage))
                        .accessibilityLabel(Localization.barcodeInfoScanMessageAccessible)
                    Text(AttributedString(Localization.barcodeInfoSearchMessage))
                        .accessibilityLabel(Localization.barcodeInfoSearchMessageAccessible)
                }
                .padding(.leading, POSSpacing.medium)

                PointOfSaleInformationModalParagraphView {
                    Text(AttributedString(Localization.legacyBarcodeInfoQuinaryMessage))
                }
            }
        }
        .onAppear(perform: {
            analytics.track(.pointOfSaleBarcodeScanningExplanationDialogShown)
        })
    }
}

struct ProductBarcodeSetupInformation: View {
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Text(Localization.productBarcodeInfoHeading)
                .font(.posHeadingBold)
                .accessibilityAddTraits(.isHeader)

            PointOfSaleInformationModalParagraphView(spacing: POSSpacing.medium) {
                Text(productSetupTextWithLink)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityLabel(Localization.productBarcodeSetupMessageAccessible)
                    .multilineTextAlignment(.center)
            }

            PointOfSaleAssets.barcodeFieldScreenshot.image
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
        .onAppear(perform: {
            analytics.track(.pointOfSaleBarcodeScanningExplanationDialogShown)
        })
    }

    private var productSetupTextWithLink: AttributedString {
        let mainContent = Localization.productBarcodeSetupMessage
        let linkText = Localization.productBarcodeSetupLinkText
        let link = Constants.detailsLink.absoluteString

        let content = String.localizedStringWithFormat(mainContent, linkText)
        var attributedText = AttributedString(content)

        if let range = attributedText.range(of: linkText),
           let url = URL(string: link) {
            var linkContainer = AttributeContainer()
                .link(url)
                .foregroundColor(Color.posPrimary)
            linkContainer.underlineStyle = .single
            attributedText[range].mergeAttributes(linkContainer)
        }
        return attributedText
    }
}

private enum Constants {
    static let detailsLink = POSConstants.URLs.pointOfSaleBarcodeScannerDocumentation.asURL()
}

private enum Localization {
    static let barcodeInfoHeading = NSLocalizedString(
        "pos.barcodeInfoModal.heading",
        value: "Barcode scanning",
        comment: "Heading for the barcode info modal in POS, introducing barcode scanning feature"
    )

    static let scannerInfoHeading = NSLocalizedString(
        "pos.barcodeScannerSetup.scannerInfo.title",
        value: "Scanner setup",
        comment: "Title format for barcode scanner setup step"
    )

    static let productBarcodeInfoHeading = NSLocalizedString(
        "pos.barcodeScannerSetup.productBarcodeInfo.title",
        value: "How to set up barcodes on products",
        comment: "Title format for a product barcode setup step"
    )

    static let legacyBarcodeInfoIntroMessage = NSLocalizedString(
        "pos.barcodeInfoModal.introMessage",
        value: "You can scan barcodes using an external scanner to quickly build a cart.",
        comment: "Introductory message in the barcode info modal in POS, explaining the use of external barcode scanners"
    )
    static let legacyBarcodeInfoPrimaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.primaryMessage",
        value: "• Set up barcodes in the \"GTIN, UPC, EAN, ISBN\" field in Products > Product Details > Inventory. ",
        comment: "Primary bullet point in the barcode info modal in POS, instructing where to set up barcodes in product details"
    )
    static let legacyBarcodeInfoMoreDetailsLink = NSLocalizedString(
        "pos.barcodeInfoModal.moreDetailsLink",
        value: "More details.",
        comment: "Link text in the barcode info modal in POS, leading to more details about barcode setup"
    )
    static let legacyBarcodeInfoMoreDetailsLinkAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.moreDetailsLink.accessible",
        value: "More details, link.",
        comment: "Accessible version of more details link in barcode info modal, announcing it as a link for screen readers"
    )
    static let legacyBarcodeInfoSecondaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.secondaryMessage.2",
        value: "• Refer to your Bluetooth barcode scanner's instructions to set HID mode. This usually " +
        "requires scanning a special barcode in the manual.",
        comment: "Secondary bullet point in the barcode info modal in POS, instructing to set scanner to HID mode"
    )
    static let legacyBarcodeInfoTertiaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.tertiaryMessage",
        value: "• Connect your barcode scanner in iOS Bluetooth settings.",
        comment: "Tertiary bullet point in the barcode info modal in POS, instructing to connect scanner via Bluetooth settings"
    )
    static let legacyBarcodeInfoQuaternaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.quaternaryMessage",
        value: "• Scan barcodes while on the item list to add products to the cart.",
        comment: "Quaternary bullet point in the barcode info modal in POS, instructing to scan barcodes on item list to add to cart"
    )
    static let legacyBarcodeInfoQuinaryMessage = NSLocalizedString(
        "pos.barcodeInfoModal.quinaryMessage",
        value: "The scanner emulates a keyboard, so sometimes it will prevent the software keyboard from showing, e.g. in search. " +
        "Tap on the keyboard icon to show it again.",
        comment: "Quinary message in the barcode info modal in POS, explaining scanner keyboard emulation and how to show software keyboard again"
    )

    static let legacyBarcodeInfoPrimaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.primaryMessage.accessible",
        value: "First: Set up barcodes in the \"G-T-I-N, U-P-C, E-A-N, I-S-B-N\" field by navigating to Products, then Product Details, then Inventory.",
        comment: "Accessible version of primary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let legacyBarcodeInfoSecondaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.secondaryMessage.accessible.2",
        value: "Second: Refer to your Bluetooth barcode scanner's instructions to set H-I-D mode. This usually " +
        "requires scanning a special barcode in the manual.",
        comment: "Accessible version of secondary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let legacyBarcodeInfoTertiaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.tertiaryMessage.accessible",
        value: "Third: Connect your barcode scanner in iOS Bluetooth settings.",
        comment: "Accessible version of tertiary bullet point in barcode info modal, without bullet character for screen readers"
    )
    static let legacyBarcodeInfoQuaternaryMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.quaternaryMessage.accessible",
        value: "Fourth: Scan barcodes while on the item list to add products to the cart.",
        comment: "Accessible version of quaternary bullet point in barcode info modal, without bullet character for screen readers"
    )

    static let barcodeInfoIntroMessage = NSLocalizedString(
        "pos.barcodeInfoModal.i2.introMessage",
        value: "You can scan barcodes using an external scanner to quickly build a cart.",
        comment: "New introductory message for barcode scanner information"
    )
    static let barcodeInfoBluetoothMessage = NSLocalizedString(
        "pos.barcodeInfoModal.i2.bluetoothMessage",
        value: "• Refer to your Bluetooth barcode scanner in iOS Bluetooth settings.",
        comment: "New message about Bluetooth barcode scanner settings"
    )
    static let barcodeInfoScanMessage = NSLocalizedString(
        "pos.barcodeInfoModal.i2.scanMessage",
        value: "• Scan barcodes while on the item list to add products to the cart.",
        comment: "New message about scanning barcodes on item list"
    )
    static let barcodeInfoSearchMessage = NSLocalizedString(
        "pos.barcodeInfoModal.i2.searchMessage",
        value: "• Ensure the search field is not enabled while scanning barcodes.",
        comment: "New message about ensuring search field is disabled during scanning"
    )

    static let barcodeInfoBluetoothMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.i2.bluetoothMessage.accessible",
        value: "First: Refer to your Bluetooth barcode scanner in iOS Bluetooth settings.",
        comment: "Accessible version of Bluetooth message without bullet character for screen readers"
    )
    static let barcodeInfoScanMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.i2.scanMessage.accessible",
        value: "Second: Scan barcodes while on the item list to add products to the cart.",
        comment: "Accessible version of scan message without bullet character for screen readers"
    )
    static let barcodeInfoSearchMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.i2.searchMessage.accessible",
        value: "Third: Ensure the search field is not enabled while scanning barcodes.",
        comment: "Accessible version of search message without bullet character for screen readers"
    )

    static let productBarcodeSetupMessage = NSLocalizedString(
        "pos.barcodeInfoModal.productSetup.message",
        value: "You can set up barcodes in the GTIN, UPC, EAN, ISBN field in the product's inventory tab. " +
        "For more details %1$@.",
        comment: "Message explaining how to set up barcodes in product inventory. %1$@ is replaced with a text and link to documentation. " +
        "For example, visit the documentation."
    )
    static let productBarcodeSetupLinkText = NSLocalizedString(
        "pos.barcodeInfoModal.productSetup.linkText",
        value: "visit the documentation",
        comment: "Link text for product barcode setup documentation. Used together with pos.barcodeInfoModal.productSetup.message."
    )
    static let productBarcodeSetupMessageAccessible = NSLocalizedString(
        "pos.barcodeInfoModal.productSetup.message.accessible",
        value: "You can set up barcodes in the G-T-I-N, U-P-C, E-A-N, I-S-B-N field in the product's inventory tab. " +
        "For more details visit the documentation, link.",
        comment: "Accessible version of product setup message, announcing link for screen readers"
    )
}

#Preview {
    PointOfSaleBarcodeScannerInformationModal(isPresented: .constant(true))
}

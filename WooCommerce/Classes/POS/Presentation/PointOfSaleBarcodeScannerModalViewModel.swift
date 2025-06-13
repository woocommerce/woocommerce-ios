import Foundation

extension PointOfSaleInformationModalViewModel {
    static var barcodeScannerModel: PointOfSaleInformationModalViewModel {
        let title = AttributedString(Localization.barcodeInfoHeading)
        let intro = Paragraph(AttributedString(Localization.barcodeInfoIntroMessage))

        let primary = AttributedString(Localization.barcodeInfoPrimaryMessage)

        var secondary = AttributedString(Localization.barcodeInfoSecondaryMessage + " ")
        var moreDetails = AttributedString(Localization.barcodeInfoMoreDetailsLink)
        moreDetails.link = Constants.detailsLink
        moreDetails.foregroundColor = .posPrimary
        secondary.append(moreDetails)
        let secondaryBullet = secondary

        let tertiary = AttributedString(Localization.barcodeInfoTertiaryMessage)
        let quaternary = AttributedString(Localization.barcodeInfoQuaternaryMessage)

        let bullets = Paragraph([primary, secondaryBullet, tertiary, quaternary])

        let quinary = Paragraph(AttributedString(Localization.barcodeInfoQuinaryMessage))

        return PointOfSaleInformationModalViewModel(
            title: title,
            paragraphs: [intro, bullets, quinary]
        )
    }

    private enum Constants {
        static let detailsLink = URL(string: "https://woocommerce.com/document/barcode-and-qr-code-scanner/")
    }

    private enum Localization {
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
        static let barcodeInfoSecondaryMessage = NSLocalizedString(
            "pos.barcodeInfoModal.secondaryMessage",
            value: "• Refer to your Bluetooth barcode scanner's instructions to set HID mode.",
            comment: "Secondary bullet point in the barcode info modal in POS, instructing to set scanner to HID mode"
        )
        static let barcodeInfoTertiaryMessage = NSLocalizedString(
            "pos.barcodeInfoModal.tertiaryMessage",
            value: "• Connect your barcode scanner in System Bluetooth settings.",
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
                "Tap on the keyboard icon to show the software keyboard back.",
            comment: "Quinary message in the barcode info modal in POS, explaining scanner keyboard emulation and how to show software keyboard again"
        )
    }
}


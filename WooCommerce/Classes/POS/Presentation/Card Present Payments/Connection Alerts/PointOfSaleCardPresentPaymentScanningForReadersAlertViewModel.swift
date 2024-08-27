import Foundation

struct PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel: Hashable {
    let title: String = Localization.title
    let instruction: String = Localization.instruction
    let imageName = PointOfSaleAssets.readerConnectionScanning.imageName
    let buttonViewModel: CardPresentPaymentsModalButtonViewModel

    init(endSearchAction: @escaping () -> Void) {
        self.buttonViewModel = CardPresentPaymentsModalButtonViewModel(title: Localization.cancel,
                                                                       actionHandler: endSearchAction)
    }
}

private extension PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.cardPresent.modalScanningForReader.title",
            value: "Scanning for reader",
            comment: "Title label for modal dialog that appears when searching for a card reader"
        )

        static let instruction = NSLocalizedString(
            "pointOfSale.cardPresent.modalScanningForReader.instruction",
            value: "To turn on your card reader, briefly press its power button.",
            comment: "Label within the modal dialog that appears when searching for a card reader"
        )

        static let cancel = NSLocalizedString(
            "pointOfSale.cardPresent.modalScanningForReader.cancelButton",
            value: "Cancel",
            comment: "Label for a cancel button"
        )
    }
}

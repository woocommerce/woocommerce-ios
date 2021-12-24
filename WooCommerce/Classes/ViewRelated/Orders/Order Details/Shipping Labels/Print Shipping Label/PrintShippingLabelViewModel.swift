import Combine
import Yosemite

/// View model for `PrintShippingLabelViewController`.
/// Performs and handles actions that might change data for UI display.
final class PrintShippingLabelViewModel {
    /// Paper size options that we support for printing a shipping label.
    /// In the future, the options could be different per geographical region.
    let paperSizeOptions: [ShippingLabelPaperSize] = [.legal, .letter, .label]

    /// Observable selected paper size.
    @Published private(set) var selectedPaperSize: ShippingLabelPaperSize?

    let shippingLabels: [ShippingLabel]
    private let stores: StoresManager

    init(shippingLabels: [ShippingLabel], stores: StoresManager = ServiceLocator.stores) {
        self.shippingLabels = shippingLabels
        self.stores = stores
    }
}

// MARK: Public methods
//
extension PrintShippingLabelViewModel {
    /// Sets the default selected paper size to the one from the first shipping label's settings, if the user has not selected one in the print UI.
    func loadShippingLabelSettingsForDefaultPaperSize() {
        guard let firstLabel = shippingLabels.first else {
            return
        }
        let action = ShippingLabelAction.loadShippingLabelSettings(shippingLabel: firstLabel) { [weak self] settings in
            guard let self = self else { return }
            guard let settings = settings, self.selectedPaperSize == nil else {
                return
            }
            // It is possible for the paper size setting (e.g. A4) to be unavailable in the paper sizes we support now (label, legal, and letter).
            // More details in: https://github.com/woocommerce/woocommerce-ios/issues/3340
            let defaultPaperSize = self.paperSizeOptions.contains(settings.paperSize) ? settings.paperSize: self.paperSizeOptions[0]
            self.selectedPaperSize = defaultPaperSize
        }
        stores.dispatch(action)
    }

    /// Updates the selected paper size (e.g. from paper size list selector).
    func updateSelectedPaperSize(_ selectedPaperSize: ShippingLabelPaperSize?) {
        self.selectedPaperSize = selectedPaperSize
    }
}

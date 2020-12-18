import Combine
import Yosemite

/// View model for `ReprintShippingLabelViewController`.
/// Performs and handles actions that might change data for UI display.
final class ReprintShippingLabelViewModel {
    /// Paper size options that we support for reprinting a shipping label.
    /// In the future, the options could be different per geographical region.
    let paperSizeOptions: [ShippingLabelPaperSize] = [.legal, .letter, .label]

    /// Observable selected paper size.
    @Published private(set) var selectedPaperSize: ShippingLabelPaperSize?

    private let shippingLabel: ShippingLabel
    private let stores: StoresManager

    init(shippingLabel: ShippingLabel, stores: StoresManager = ServiceLocator.stores) {
        self.shippingLabel = shippingLabel
        self.stores = stores
    }
}

// MARK: Public methods
//
extension ReprintShippingLabelViewModel {
    /// Sets the default selected paper size to the one from shipping label settings, if the user has not selected one in the reprint UI.
    func loadShippingLabelSettingsForDefaultPaperSize() {
        let action = ShippingLabelAction.loadShippingLabelSettings(shippingLabel: shippingLabel) { [weak self] settings in
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

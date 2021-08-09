import Foundation
import Yosemite

/// View model for ShippingLabelCustomsFormInput
final class ShippingLabelCustomsFormInputViewModel: ObservableObject {
    @Published var returnOnNonDelivery: Bool

    /// Input customs forms to be updated
    ///
    private let customsForm: ShippingLabelCustomsForm

    init(customsForm: ShippingLabelCustomsForm) {
        self.customsForm = customsForm
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelCustomsFormInputViewModel {}

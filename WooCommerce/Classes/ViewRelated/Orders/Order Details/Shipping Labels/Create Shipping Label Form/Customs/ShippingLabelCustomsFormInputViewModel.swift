import Foundation
import Yosemite

/// View model for ShippingLabelCustomsFormInput
final class ShippingLabelCustomsFormInputViewModel: ObservableObject {
    /// Whether to return package if delivery fails.
    ///
    @Published var returnOnNonDelivery: Bool

    /// Content type of the items to be declared in the customs form.
    ///
    @Published var contentType: ShippingLabelCustomsForm.ContentsType

    /// Input customs forms to be updated
    ///
    private(set) var customsForm: ShippingLabelCustomsForm

    init(customsForm: ShippingLabelCustomsForm) {
        self.customsForm = customsForm
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
        self.contentType = customsForm.contentsType
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelCustomsFormInputViewModel {}

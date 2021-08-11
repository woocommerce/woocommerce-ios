import Foundation
import Yosemite

/// View model for ShippingLabelCustomsFormInput
final class ShippingLabelCustomsFormInputViewModel: ObservableObject {
    /// Whether to return package if delivery fails.
    ///
    @Published var returnOnNonDelivery: Bool

    /// Content type of the items to be declared in the customs form.
    ///
    @Published var contentsType: ShippingLabelCustomsForm.ContentsType

    /// Description of contents, required if contentsType is other.
    ///
    @Published var contentExplanation: String

    /// Input customs forms to be updated
    ///
    private(set) var customsForm: ShippingLabelCustomsForm

    init(customsForm: ShippingLabelCustomsForm) {
        self.customsForm = customsForm
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
        self.contentsType = customsForm.contentsType
        self.contentExplanation = customsForm.contentExplanation
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelCustomsFormInputViewModel {}

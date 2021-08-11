import Foundation
import Yosemite

/// View model for ShippingLabelCustomsFormInput
final class ShippingLabelCustomsFormInputViewModel: ObservableObject {
    /// ID of current package.
    ///
    let packageID: String

    /// Name of current package.
    ///
    let packageName: String

    /// Whether to return package if delivery fails.
    ///
    @Published var returnOnNonDelivery: Bool

    /// Content type of the items to be declared in the customs form.
    ///
    @Published var contentsType: ShippingLabelCustomsForm.ContentsType

    /// Description of contents, required if contentsType is other.
    ///
    @Published var contentExplanation: String

    /// Restriction type of items to be declared in the customs form.
    ///
    @Published var restrictionType: ShippingLabelCustomsForm.RestrictionType

    /// Description of restriction type, required if the type is other.
    ///
    @Published var restrictionComments: String

    /// International tax number for package.
    ///
    @Published var itn: String

    /// Items contained in the package.
    ///
    @Published var items: [ShippingLabelCustomsForm.Item] {
        didSet {
            itemViewModels = items.map { .init(item: $0) }
        }
    }

    /// References of item view models.
    ///
    private(set) var itemViewModels: [ShippingLabelCustomsFormItemDetailsViewModel]

    /// Validated customs form
    ///
    private(set) var validatedCustomsForm: ShippingLabelCustomsForm?

    init(customsForm: ShippingLabelCustomsForm) {
        self.packageID = customsForm.packageID
        self.packageName = customsForm.packageName
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
        self.contentsType = customsForm.contentsType
        self.contentExplanation = customsForm.contentExplanation
        self.restrictionType = customsForm.restrictionType
        self.restrictionComments = customsForm.restrictionComments
        self.itn = customsForm.itn
        self.items = customsForm.items
        self.itemViewModels = customsForm.items.map { .init(item: $0) }
    }
}

// MARK: - Helper methods
//
private extension ShippingLabelCustomsFormInputViewModel {}

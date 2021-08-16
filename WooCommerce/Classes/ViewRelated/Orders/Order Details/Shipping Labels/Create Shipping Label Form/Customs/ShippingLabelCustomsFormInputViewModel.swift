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

    /// Internal transaction number for package.
    ///
    @Published var itn: String

    /// Items contained in the package.
    ///
    @Published var items: [ShippingLabelCustomsForm.Item]

    /// References of item view models.
    ///
    private(set) var itemViewModels: [ShippingLabelCustomsFormItemDetailsViewModel]

    /// Validated customs form
    ///
    private(set) var validatedCustomsForm: ShippingLabelCustomsForm?

    /// Persisted countries to send to item detail forms.
    ///
    private let allCountries: [Country]

    /// Currency to send to item detail forms.
    ///
    private let currency: String

    /// Whether ITN validation is required.
    ///
    private let itnValidationRequired: Bool

    init(customsForm: ShippingLabelCustomsForm, countries: [Country], itnValidationRequired: Bool, currency: String) {
        self.packageID = customsForm.packageID
        self.packageName = customsForm.packageName
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
        self.contentsType = customsForm.contentsType
        self.contentExplanation = customsForm.contentExplanation
        self.restrictionType = customsForm.restrictionType
        self.restrictionComments = customsForm.restrictionComments
        self.itn = customsForm.itn
        self.items = customsForm.items
        self.allCountries = countries
        self.currency = currency
        self.itnValidationRequired = itnValidationRequired
        self.itemViewModels = customsForm.items.map { .init(item: $0, countries: countries, currency: currency) }

        resetContentExplanationIfNeeded()
        resetRestrictionCommentsIfNeeded()
    }
}

// MARK: - Validation
//
extension ShippingLabelCustomsFormInputViewModel {
    var hasValidContentExplanation: Bool {
        if contentsType == .other, contentExplanation.isEmpty {
            return false
        }
        return true
    }

    var hasValidRestrictionComments: Bool {
        if restrictionType == .other, restrictionComments.isEmpty {
            return false
        }
        return true
    }

    var missingITN: Bool {
        itnValidationRequired && itn.isEmpty
    }

    var hasValidITN: Bool {
        if itn.isNotEmpty,
           itn.range(of: Constants.itnRegex, options: .regularExpression, range: nil, locale: nil) == nil {
            return false
        }

        return true
    }
}

// MARK: - Private helpers
//
private extension ShippingLabelCustomsFormInputViewModel {
    /// Reset content explanation if content type is not Other.
    ///
    func resetContentExplanationIfNeeded() {
        $contentsType
            .filter { $0 != .other }
            .map { _ -> String in "" }
            .assign(to: &$contentExplanation)
    }

    /// Reset restriction comments if restriction type is not Other.
    ///
    func resetRestrictionCommentsIfNeeded() {
        $restrictionType
            .filter { $0 != .other }
            .map { _ -> String in "" }
            .assign(to: &$restrictionComments)
    }
}

private extension ShippingLabelCustomsFormInputViewModel {
    enum Constants {
        static let itnRegex = "^(?:(?:AES X\\d{14})|(?:NOEEI 30\\.\\d{1,2}(?:\\([a-z]\\)(?:\\(\\d\\))?)?))$"
    }
}

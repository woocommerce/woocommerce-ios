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

    /// Whether all fields and items are validated.
    ///
    @Published private(set) var isFormValidated: Bool = false

    /// Validated customs form
    ///
    var validatedCustomsForm: ShippingLabelCustomsForm? {
        guard !missingContentExplanation,
              !missingRestrictionComments,
              !missingITNForDestination,
              !missingITNForClassesAbove2500usd,
              !invalidITN,
              itemViewModels.filter({ $0.validatedItem == nil }).isEmpty else {
            return nil
        }
        return ShippingLabelCustomsForm(packageID: packageID,
                                        packageName: packageName,
                                        contentsType: contentsType,
                                        contentExplanation: contentExplanation,
                                        restrictionType: restrictionType,
                                        restrictionComments: restrictionComments,
                                        nonDeliveryOption: returnOnNonDelivery ? .return : .abandon,
                                        itn: itn,
                                        items: itemViewModels.compactMap { $0.validatedItem })
    }

    /// Destination country for the shipment.
    ///
    let destinationCountry: Country

    /// Persisted countries to send to item detail forms.
    ///
    private let allCountries: [Country]

    /// Currency to send to item detail forms.
    ///
    private let currency: String

    /// Whether ITN validation is required.
    ///
    private lazy var itnValidationRequired: Bool = {
        Constants.uspsITNRequiredDestinations.contains(destinationCountry.code)
    }()

    init(customsForm: ShippingLabelCustomsForm, destinationCountry: Country, countries: [Country], currency: String) {
        self.packageID = customsForm.packageID
        self.packageName = customsForm.packageName
        self.returnOnNonDelivery = customsForm.nonDeliveryOption == .return
        self.contentsType = customsForm.contentsType
        self.contentExplanation = customsForm.contentExplanation
        self.restrictionType = customsForm.restrictionType
        self.restrictionComments = customsForm.restrictionComments
        self.itn = customsForm.itn
        self.items = customsForm.items
        self.destinationCountry = destinationCountry
        self.allCountries = countries
        self.currency = currency
        self.itemViewModels = customsForm.items.map { .init(item: $0, countries: countries, currency: currency) }

        configureValidationCheck()
        resetContentExplanationIfNeeded()
        resetRestrictionCommentsIfNeeded()
    }
}

// MARK: - Validation
//
extension ShippingLabelCustomsFormInputViewModel {
    var missingContentExplanation: Bool {
        checkMissingContentExplanation(contentExplanation, with: contentsType)
    }

    var missingRestrictionComments: Bool {
        checkMissingRestrictionComment(restrictionComments, with: restrictionType)
    }

    var missingITNForDestination: Bool {
        checkMissingITNForDestination(itn)
    }

    var missingITNForClassesAbove2500usd: Bool {
        checkMissingITNForClassesAbove2500usd(itn)
    }

    var invalidITN: Bool {
        checkInvalidITN(itn)
    }
}

// MARK: - Private validation helpers
//
private extension ShippingLabelCustomsFormInputViewModel {
    func checkMissingContentExplanation(_ contentExplanation: String, with contentsType: ShippingLabelCustomsForm.ContentsType) -> Bool {
        if contentsType == .other, contentExplanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    func checkMissingRestrictionComment(_ restrictionComment: String, with restrictionType: ShippingLabelCustomsForm.RestrictionType) -> Bool {
        if restrictionType == .other, restrictionComments.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }
        return false
    }

    func checkMissingITNForDestination(_ itn: String) -> Bool {
        if itnValidationRequired && itn.isEmpty {
            return true
        }
        return false
    }

    var missingITNForClassesAbove2500usd: Bool {
        // TODO: check for accumulated value of each tariff number.
        return false
    }

    func checkInvalidITN(_ itn: String) -> Bool {
        if itn.isNotEmpty,
           itn.range(of: Constants.itnRegex, options: .regularExpression, range: nil, locale: nil) == nil {
            return true
        }
        return false
    }

    func configureValidationCheck() {
        let groupOne = $contentExplanation.combineLatest($contentsType)
        let groupTwo = $itn.combineLatest($restrictionType, $restrictionComments)
        groupOne.combineLatest(groupTwo)
            .map { [weak self] groupOne, groupTwo -> Bool in
                guard let self = self else {
                    return false
                }
                let (contentExplanation, contentsType) = groupOne
                let (itn, restrictionType, restrictionComments) = groupTwo
                return !self.checkMissingContentExplanation(contentExplanation, with: contentsType) &&
                    !self.checkMissingRestrictionComment(restrictionComments, with: restrictionType) &&
                    !self.checkMissingITNForDestination(itn) &&
                    !self.checkMissingITNForClassesAbove2500usd(itn) &&
                    !self.checkInvalidITN(itn)
            }
            .removeDuplicates()
            .assign(to: &$isFormValidated)
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
        static let minimumValueRequiredForITNValidation: Decimal = 2_500

        // These destination countries require an ITN regardless of shipment value
        static let uspsITNRequiredDestinations = ["IR", "SY", "KP", "CU", "SD"]
    }
}

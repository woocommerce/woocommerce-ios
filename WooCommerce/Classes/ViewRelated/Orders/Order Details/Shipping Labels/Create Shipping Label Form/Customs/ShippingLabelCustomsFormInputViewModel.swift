import Combine
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
    let items: [ShippingLabelCustomsForm.Item]

    /// References of item view models.
    ///
    let itemViewModels: [ShippingLabelCustomsFormItemDetailsViewModel]

    /// Whether all fields and items are validated.
    ///
    @Published private(set) var validForm: Bool = false

    /// Destination country for the shipment.
    ///
    let destinationCountry: Country

    /// Persisted countries to send to item detail forms.
    ///
    private let allCountries: [Country]

    /// Currency to send to item detail forms.
    ///
    private let currency: String

    /// Whether ITN validation is required for the destination country.
    ///
    private lazy var itnRequiredForDestination: Bool = {
        Constants.uspsITNRequiredDestinations.contains(destinationCountry.code)
    }()

    /// Validation states of all items.
    ///
    @Published private var itemsValidation: [Int64: Bool] = [:]

    /// Tariff numbers with total values above $2500.
    ///
    @Published private var classesAbove2500usd: [String] = []

    /// Keeping track of all items tariff numbers and total values to calculate `classesAbove2500usd`.
    ///
    private var itemTariffNumbersAndValues: [Int64: (hsTariffNumber: String, totalValue: Decimal)] = [:] {
        didSet {
            configureClassesAbove2500usd()
        }
    }

    /// References to keep the Combine subscriptions alive with the class.
    ///
    private var cancellables: Set<AnyCancellable> = []

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

        configureItemsValidation()
        configureFormValidation()
        configureItemTariffNumbersAndValues()
        resetContentExplanationIfNeeded()
        resetRestrictionCommentsIfNeeded()
    }
}

// MARK: - Validation
//
extension ShippingLabelCustomsFormInputViewModel {
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
        checkMissingITN(itn, for: classesAbove2500usd)
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
        if itnRequiredForDestination && itn.isEmpty {
            return true
        }
        return false
    }

    func checkMissingITN(_ itn: String, for classesAbove2500usd: [String]) -> Bool {
        if classesAbove2500usd.isNotEmpty && itn.isEmpty {
            return true
        }
        return false
    }

    func checkInvalidITN(_ itn: String) -> Bool {
        if itn.isNotEmpty,
           itn.range(of: Constants.itnRegex, options: .regularExpression, range: nil, locale: nil) == nil {
            return true
        }
        return false
    }

    /// Observe validation state of each item and save them by product ID.
    ///
    func configureItemsValidation() {
        itemViewModels.forEach { viewModel in
            viewModel.$validItem
                .sink { [weak self] isValid in
                    self?.itemsValidation[viewModel.productID] = isValid
                }
                .store(in: &cancellables)
        }
    }

    /// Observe all fields and item validation states to decide validity of the form.
    ///
    func configureFormValidation() {
        let groupOne = $classesAbove2500usd.combineLatest($contentsType, $contentExplanation)
        let groupTwo = $itn.combineLatest($restrictionType, $restrictionComments, $itemsValidation)
        groupOne.combineLatest(groupTwo)
            .map { [weak self] groupOne, groupTwo -> Bool in
                guard let self = self else {
                    return false
                }
                let (classesAbove2500usd, contentsType, contentExplanation) = groupOne
                let (itn, restrictionType, restrictionComments, itemsValidation) = groupTwo
                return !self.checkMissingContentExplanation(contentExplanation, with: contentsType) &&
                    !self.checkMissingRestrictionComment(restrictionComments, with: restrictionType) &&
                    !self.checkMissingITNForDestination(itn) &&
                    !self.checkMissingITN(itn, for: classesAbove2500usd) &&
                    !self.checkInvalidITN(itn) &&
                    itemsValidation.values.first(where: { !$0 }) == nil
            }
            .removeDuplicates()
            .assign(to: &$validForm)
    }
}

// MARK: - Private helpers
//
private extension ShippingLabelCustomsFormInputViewModel {
    /// Observe changes of each item's tariff number and value,
    /// and save them by product ID.
    ///
    func configureItemTariffNumbersAndValues() {
        itemViewModels.forEach { viewModel in
            viewModel.$validatedHSTariffNumber.combineLatest(viewModel.$validatedTotalValue)
                .sink { [weak self] number, totalValue in
                    if let number = number, number.isNotEmpty,
                       let totalValue = totalValue {
                        self?.itemTariffNumbersAndValues[viewModel.productID] = (hsTariffNumber: number, totalValue: totalValue)
                    } else {
                        self?.itemTariffNumbersAndValues.removeValue(forKey: viewModel.productID)
                    }
                }
                .store(in: &cancellables)
        }
    }

    /// Check for items and list ones with same HS Tariff Number
    /// whose values accumulate to more than $2500.
    ///
    func configureClassesAbove2500usd() {
        classesAbove2500usd = itemTariffNumbersAndValues.values
            .reduce([String: Decimal]()) { accumulator, item in
                var result = accumulator
                if let currentTotal = result[item.hsTariffNumber] {
                    result[item.hsTariffNumber] = currentTotal + item.totalValue
                } else {
                    result[item.hsTariffNumber] = item.totalValue
                }
                return result
            }
            .filter { $0.value > Constants.minimumValueRequiredForITNValidation }
            .keys
            .map { String($0) }
    }

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
        // Reference: https://git.io/J0K0r
        static let itnRegex = "^(?:(?:AES X\\d{14})|(?:NOEEI 30\\.\\d{1,2}(?:\\([a-z]\\)(?:\\(\\d\\))?)?))$"
        static let minimumValueRequiredForITNValidation: Decimal = 2_500

        // These destination countries require an ITN regardless of shipment value
        static let uspsITNRequiredDestinations = ["IR", "SY", "KP", "CU", "SD"]
    }
}

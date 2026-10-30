import Yosemite
import SwiftUI
import Combine
import protocol Storage.StorageManagerType

final class WooShippingCustomsItemViewModel: ObservableObject {
    @Published var title: String
    @Published var description: String = ""
    @Published var hsTariffNumber: String = ""
    @Published var valuePerUnit: String = ""
    @Published var weightPerUnit: String = ""
    @Published var sku: String = ""
    @Published var manufacturerPartNumber: String = ""
    @Published var gtin: String = ""
    @Published var hasNoBarcode = false {
        didSet {
            if hasNoBarcode {
                gtin = ""
            }
        }
    }

    @Published private var originCountryCode: String?

    private let storageManager: StorageManagerType
    let currencySymbol: String

    let itemProductID: Int64
    let itemQuantity: Decimal

    let hsTariffURL = WooConstants.URLs.hsTariffURL.asURL()

    private lazy var resultsController: ResultsController<StorageCountry> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, matching: nil, sortedBy: [descriptor])
    }()

    @Published private(set) var selectedCountry: Country?

    @Published private(set) var countries: [Country] = []

    @Published private(set) var totalValue: Decimal = 0

    /// View model for selecting a country from a list.
    @MainActor
    var countrySelectorVM: CountrySelectorViewModel {
        let selectedCountryBinding = Binding<AreaSelectorCommandProtocol?>(
            get: { self.selectedCountry },
            set: { self.selectedCountry = $0 as? Country }
        )
        return CountrySelectorViewModel(countries: countries, selected: selectedCountryBinding)
    }

    var isValidTariffNumber: Bool {
        return HSTariffNumberValidator.isNumberValid(hsTariffNumber)
    }

    var sanitizedHSTariffNumber: String {
        HSTariffNumberValidator.sanitize(hsTariffNumber)
    }

    var isValidWeight: Bool {
        return Self.isWeightValid(weightPerUnit)
    }

    var isDescriptionTooLong: Bool {
        Self.isDescriptionTooLong(description, isDescriptionLengthLimitRequired: isDescriptionLengthLimitRequired)
    }

    var isValidDescription: Bool {
        Self.isDescriptionValid(description, isDescriptionLengthLimitRequired: isDescriptionLengthLimitRequired)
    }

    @Published var requiredInformationIsEntered: Bool = false

    private var cancellables = Set<AnyCancellable>()

    /// WOOMOB-891
    /// Shipments with a EU destination address must contain HS tariff number
    ///
    /// Introduced to enforce tariff validation
    /// if `true` then `hsTariffNumber` must be valid for `requiredInformationIsEntered` to be `true`
    @Published private(set) var isHSTariffNumberRequired: Bool = false
    @Published private(set) var isDescriptionLengthLimitRequired: Bool = false
    @Published private(set) var areEUProductIdentifiersRequired = false

    /// EU product identifiers to send: nil when they aren't asked for or are empty, and Y081 for "No barcode".
    var euProductIdentifiersToSend: (code: String?, manufacturerProductID: String?, standardizedProductID: String?) {
        guard areEUProductIdentifiersRequired else {
            return (nil, nil, nil)
        }

        let trimmedSKU = sku.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedManufacturerPartNumber = manufacturerPartNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGTIN = gtin.trimmingCharacters(in: .whitespacesAndNewlines)
        return (code: trimmedSKU.isEmpty ? nil : trimmedSKU,
                manufacturerProductID: trimmedManufacturerPartNumber.isEmpty ? nil : trimmedManufacturerPartNumber,
                standardizedProductID: hasNoBarcode ? Constants.noBarcodeProductIdentifier : trimmedGTIN.isEmpty ? nil : trimmedGTIN)
    }

    var skuValidationError: String? {
        guard areEUProductIdentifiersRequired else { return nil }
        return Self.identifierError(for: sku, emptyMessage: Localization.identifierRequired)
    }

    var manufacturerPartNumberValidationError: String? {
        guard areEUProductIdentifiersRequired else { return nil }
        return Self.identifierError(for: manufacturerPartNumber, emptyMessage: Localization.identifierRequired)
    }

    var gtinValidationError: String? {
        guard areEUProductIdentifiersRequired, !hasNoBarcode else { return nil }
        return Self.identifierError(for: gtin, emptyMessage: Localization.gtinRequired)
    }

    init(itemName: String,
         itemProductID: Int64,
         itemQuantity: Decimal,
         itemValue: Double,
         itemWeight: Double,
         currencySymbol: String,
         originCountryCode: AnyPublisher<String?, Never>? = nil,
         isHSTariffNumberRequired: AnyPublisher<Bool, Never>? = nil,
         isDescriptionLengthLimitRequired: AnyPublisher<Bool, Never>? = nil,
         areEUProductIdentifiersRequired: AnyPublisher<Bool, Never>? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.title = itemName
        self.description = itemName
        self.itemProductID = itemProductID
        self.itemQuantity = itemQuantity
        self.valuePerUnit = String(itemValue)

        /// Skip zero weight
        if Self.isWeightNonZero(itemWeight) {
            self.weightPerUnit = String(itemWeight)
        }

        self.currencySymbol = currencySymbol
        self.storageManager = storageManager

        originCountryCode?
            .assign(to: &$originCountryCode)

        isHSTariffNumberRequired?
            .assign(to: &$isHSTariffNumberRequired)

        isDescriptionLengthLimitRequired?
            .assign(to: &$isDescriptionLengthLimitRequired)

        areEUProductIdentifiersRequired?
            .assign(to: &$areEUProductIdentifiersRequired)

        fetchCountries()

        combineToPreselectCountry()
        combineRequiredInformationIsEntered()
        combineTotalItemValue()
    }

    func prefillEUProductIdentifiers(_ identifiers: WooShippingEUProductIdentifiers?) {
        guard let identifiers else { return }

        if sku.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sku = identifiers.sku
        }
        if manufacturerPartNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            manufacturerPartNumber = identifiers.manufacturerProductID
        }
        guard gtin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !hasNoBarcode else { return }

        if identifiers.standardizedProductID == Constants.noBarcodeProductIdentifier {
            hasNoBarcode = true
        } else {
            gtin = identifiers.standardizedProductID
        }
    }
}

private extension WooShippingCustomsItemViewModel {
    func combineToPreselectCountry() {
        $originCountryCode
            .compactMap { $0 }
            .first(where: { !$0.isEmpty }) /// Make sure to only handle the initial value
            .combineLatest($countries)
            .map { code, countries in
                return countries.first(where: { $0.code == code })
            }
            .assign(to: &$selectedCountry)
    }

    func fetchCountries() {
        resultsController.onDidChangeContent = { [weak self] in
            self?.updateCountries()
        }

        resultsController.onDidResetContent = { [weak self] in
            self?.updateCountries()
        }

        try? resultsController.performFetch()
        updateCountries()
    }

    func updateCountries() {
        countries = resultsController.fetchedObjects
    }

    func combineRequiredInformationIsEntered() {
        Publishers.CombineLatest4(
            $description,
            $valuePerUnit,
            $weightPerUnit,
            $selectedCountry
        )
        .combineLatest($hsTariffNumber, $isHSTariffNumberRequired, $isDescriptionLengthLimitRequired)
        .combineLatest($sku)
        .combineLatest($manufacturerPartNumber)
        .combineLatest($gtin)
        .combineLatest($hasNoBarcode)
        .combineLatest($areEUProductIdentifiersRequired)
        .sink { [weak self] result in
            guard let self else { return }

            let (((((baseInformation, sku), manufacturerPartNumber), gtin), hasNoBarcode), areEUProductIdentifiersRequired) = result
            let (itemInformation, hsTariffNumber, isHSTariffNumberRequired, isDescriptionLengthLimitRequired) = baseInformation
            let (description, valuePerUnit, weightPerUnit, selectedCountry) = itemInformation

            let hsTariffNumberRequirementMet = (hsTariffNumber.isEmpty && !isHSTariffNumberRequired) ||
                (HSTariffNumberValidator.isNumberValid(hsTariffNumber) && hsTariffNumber.isNotEmpty)
            let identifiersRequirementMet = !areEUProductIdentifiersRequired ||
                (Self.identifierError(for: sku, emptyMessage: Localization.identifierRequired) == nil &&
                 Self.identifierError(for: manufacturerPartNumber, emptyMessage: Localization.identifierRequired) == nil &&
                 (hasNoBarcode || Self.identifierError(for: gtin, emptyMessage: Localization.gtinRequired) == nil))

            requiredInformationIsEntered = Self.isDescriptionValid(description, isDescriptionLengthLimitRequired: isDescriptionLengthLimitRequired) &&
            valuePerUnit.isNotEmpty &&
            Self.isWeightValid(weightPerUnit) &&
            selectedCountry != nil &&
            hsTariffNumberRequirementMet &&
            identifiersRequirementMet
        }
        .store(in: &cancellables)
    }

    func combineTotalItemValue() {
        $valuePerUnit.map { [weak self] valuePerUnit in
            guard
                let self,
                currencySymbol == "$",
                let valuePerUnitDecimal = Decimal(string: valuePerUnit)
            else {
                return 0
            }

            return valuePerUnitDecimal * itemQuantity
        }
        .assign(to: &$totalValue)
    }

    /// Specifically introduced to check for a `0` value
    static func isWeightValid(_ weightString: String) -> Bool {
        return isWeightNonZero(Double(weightString) ?? 0)
    }

    static func isWeightNonZero(_ weightValue: Double) -> Bool {
        return weightValue > 0
    }

    static func isDescriptionValid(_ description: String, isDescriptionLengthLimitRequired: Bool) -> Bool {
        return description.isNotEmpty && !isDescriptionTooLong(description, isDescriptionLengthLimitRequired: isDescriptionLengthLimitRequired)
    }

    static func isDescriptionTooLong(_ description: String, isDescriptionLengthLimitRequired: Bool) -> Bool {
        return isDescriptionLengthLimitRequired && description.count > Constants.maximumUSPSDomesticMailDescriptionLength
    }

    private static func identifierError(for value: String, emptyMessage: String) -> String? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.isEmpty {
            return emptyMessage
        }
        guard trimmedValue.unicodeScalars.count > Constants.maximumEUProductIdentifierLength else {
            return nil
        }
        return String.localizedStringWithFormat(Localization.identifierTooLong, Constants.maximumEUProductIdentifierLength)
    }

    private enum Constants {
        static let maximumEUProductIdentifierLength = 64
        static let noBarcodeProductIdentifier = "Y081"
        static let maximumUSPSDomesticMailDescriptionLength = 30
    }

    private enum Localization {
        static let identifierRequired = NSLocalizedString(
            "wooShipping.customsItems.euProductIdentifier.required",
            value: "Required for shipments to the EU",
            comment: "Error shown when a required EU product identifier is empty"
        )
        static let gtinRequired = NSLocalizedString(
            "wooShipping.customsItems.gtin.required",
            value: "Enter the GTIN/EAN, or select \"No barcode\"",
            comment: "Error shown when a required GTIN is empty and the no barcode option is not selected"
        )
        static let identifierTooLong = NSLocalizedString(
            "wooShipping.customsItems.euProductIdentifier.tooLong",
            value: "Must be %1$d characters or fewer.",
            comment: "Error shown when an EU product identifier exceeds the allowed character count"
        )
    }
}

/// Follows validation logic from `woocommerce-shipping/client/utils/customs.ts`
enum HSTariffNumberValidator {
    static let pattern = "^(\\d{1,2}\\.?){3,6}$"

    /// Check if the HS Tariff Number is valid.
    /// It should be a string of 6 to 12 digits, with optional dots in between every 2 digits.
    /// - Parameter tariffNumber: The tariff number string.
    /// - Returns: `Bool` if tariff number valid or not.
    static func isNumberValid(_ tariffNumber: String) -> Bool {
        if tariffNumber.isEmpty {
            return true
        }

        let patternRange = tariffNumber.range(
            of: pattern,
            options: .regularExpression
        )

        if patternRange == nil {
            return false
        }

        let digitsOnly = tariffNumber.components(
            separatedBy: CharacterSet.decimalDigits.inverted
        ).joined()
        let count = digitsOnly.count
        return count >= 6 && count <= 12
    }

    /// Sanitize the HS Tariff Number
    /// Remove all non-digit characters
    /// - Parameter tariffNumber: The tariff number string.
    /// - Returns: Tariff string without non-digit characters
    static func sanitize(_ tariffNumber: String) -> String {
        return tariffNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
}

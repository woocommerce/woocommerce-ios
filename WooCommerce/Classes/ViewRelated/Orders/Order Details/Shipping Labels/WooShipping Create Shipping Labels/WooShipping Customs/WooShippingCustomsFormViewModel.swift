import SwiftUI
import Yosemite
import Combine
import WooFoundation
import protocol Storage.StorageManagerType

final class WooShippingCustomsFormViewModel: ObservableObject {
    enum ITNValidationError {
        case missingForTotalShipmentValue
        case missingForTariffClass
        case missingForRequiredDestination
        case invalidFormat
    }

    @Published var internationalTransactionNumber = ""
    @Published var itnValidationError: ITNValidationError?
    @Published var returnToSenderIfNotDelivered = false

    @Published var requiredInformationIsEntered = false
    @Published private var itemsRequiredInformationIsEntered = false

    @Published var contentExplanation = ""
    @Published var restrictionDetails = ""
    @Published var contentType: WooShippingContentType = .merchandise
    @Published var restrictionType: WooShippingRestrictionType = .none

    let itnInfoURL = URL(string: "https://pe.usps.com/text/imm/immc5_010.htm")

    @Published private(set) var isMissingITN = false
    @Published private(set) var destinationCountryCode: String?

    private var cancellables = Set<AnyCancellable>()

    /// The callback that passes the `ShippingLabelCustomsForm` to outer environment
    /// Called when:
    /// - The customs form is closed
    /// - The customs form is pre-filled with data and all required fields are completed.
    private let onFormReady: (ShippingLabelCustomsForm) -> ()

    @Published private(set) var itemsViewModels: [WooShippingCustomsItemViewModel] = []

    init(order: Order,
         shipment: Shipment,
         originCountryCode: AnyPublisher<String?, Never>? = nil,
         isHSTariffNumberRequired: AnyPublisher<Bool, Never>? = nil,
         storageManager: StorageManagerType = ServiceLocator.storageManager,
         onFormReady: @escaping (ShippingLabelCustomsForm) -> ()) {
        self.onFormReady = onFormReady

        itemsViewModels = shipment.items.map {
            WooShippingCustomsItemViewModel(itemName: $0.name,
                                            itemProductID: $0.productOrVariationID,
                                            itemQuantity: $0.quantity,
                                            itemValue: $0.value,
                                            itemWeight: $0.weight,
                                            currencySymbol: currencySymbol(from: order),
                                            originCountryCode: originCountryCode,
                                            isHSTariffNumberRequired: isHSTariffNumberRequired,
                                            storageManager: storageManager)
        }

        listenToItemsRequiredInformationValues()
        listenForRequiredInformation()
        listenForInternationalTransactionNumberIsRequired()
        listenForRequiredInformationCompletedUponPreFill()
    }

    /// WOOMOB-734
    /// Solves the issue where a pre-filled form becomes complete without a manual submission
    ///
    /// Listens for the `requiredInformationIsEntered` state
    /// As soon as all required info is entered, calls the `emitForm` just once
    func listenForRequiredInformationCompletedUponPreFill() {
        $requiredInformationIsEntered
            .first { $0 == true }
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.emitForm()
                }
            }
            .store(in: &cancellables)
    }

    func onDismiss() {
        emitForm()
    }

    func updateDestinationCountry(code: String) {
        destinationCountryCode = code
    }
}

private extension WooShippingCustomsFormViewModel {
    func listenForRequiredInformation() {
        let firstBatch = Publishers.CombineLatest4($contentType, $contentExplanation, $restrictionType, $restrictionDetails)
        let secondBatch = Publishers.CombineLatest($itemsRequiredInformationIsEntered, $isMissingITN)

        firstBatch.combineLatest(secondBatch)
            .map { firstBatchOutput, secondBatchOutput -> Bool in
                let (contentType, contentExplanation, restrictionType, restrictionDetails) = firstBatchOutput
                let (itemsRequiredInfo, isMissingITN) = secondBatchOutput
                return (contentType != .other || contentExplanation.isNotEmpty) &&
                (restrictionType != .other || restrictionDetails.isNotEmpty) &&
                itemsRequiredInfo &&
                !isMissingITN
            }
            .assign(to: &$requiredInformationIsEntered)
    }

    func listenForInternationalTransactionNumberIsRequired() {
        $itnValidationError
            .map { error -> Bool in
                guard let error else {
                    return false
                }
                if case .invalidFormat = error {
                    return false
                }
                return true
            }
            .assign(to: &$isMissingITN)

        let totalItemValue = $itemsViewModels
           .map { childViewModels in
               childViewModels.map { $0.$totalValue.eraseToAnyPublisher() }
           }
           .flatMap { childPublishers in
               childPublishers.combineLatest()
           }
           .map { values in
               return values.reduce(0) { partialResult, value in
                   return partialResult + value
               }
           }

        $internationalTransactionNumber.combineLatest(
            totalItemValue,
            $destinationCountryCode)
        .map { input -> ITNValidationError? in
            let (itn, totalItemValue, countryCode) = input
            guard itn.isEmpty else {
                return ITNNumberValidator.isValid(itn) ? nil : .invalidFormat
            }

            if totalItemValue > Constants.minimumValueForRequiredITN {
                return .missingForTotalShipmentValue
            }

            guard let countryCode, countryCode != Constants.ITNNonRequiredDestination else {
                return nil
            }

            if Constants.ITNRequiredDestinationForUSPS.contains(countryCode) {
                return .missingForRequiredDestination
            }

            return nil
        }
        .assign(to: &$itnValidationError)
    }

    func listenToItemsRequiredInformationValues() {
        // Listen to the items required information and enable the button depending on it
        $itemsViewModels
            .map { childViewModels in
                childViewModels.map { $0.$requiredInformationIsEntered.eraseToAnyPublisher() }
            }
            .flatMap { childPublishers in
                childPublishers.combineLatest() // Combine the latest values from all child publishers
            }
            .map { childValidityArray in
                childValidityArray.allSatisfy { $0 } // Check if all are valid
            }
            .sink { [weak self] value in
                self?.itemsRequiredInformationIsEntered = value
            }
            .store(in: &cancellables)
    }

    func currencySymbol(from order: Order) -> String {
        guard let currencyCode = CurrencyCode(rawValue: order.currency) else {
            return ""
        }
        return ServiceLocator.currencySettings.symbol(from: currencyCode)
    }

    private func emitForm() {
        /// Ignoring `packageID` and `packageName` as these are not needed in WooShipping plugin, only in WCS&T
        let form = ShippingLabelCustomsForm(
            packageID: "",
            packageName: "",
            contentsType: contentType.toFormContentsType(),
            contentExplanation: contentType == .other ? contentExplanation : "",
            restrictionType: restrictionType.toFormRestrictionType(),
            restrictionComments: restrictionType == .other ? restrictionDetails : "",
            nonDeliveryOption: returnToSenderIfNotDelivered ? .return : .abandon,
            itn: ITNNumberValidator.isValid(internationalTransactionNumber) ? internationalTransactionNumber : "",
            items: itemsViewModels.map {
                ShippingLabelCustomsForm.Item(
                    description: $0.description,
                    quantity: $0.itemQuantity,
                    value: Double($0.valuePerUnit) ?? 0,
                    weight: Double($0.weightPerUnit) ?? 0,
                    hsTariffNumber: $0.isValidTariffNumber ? $0.sanitizedHSTariffNumber : "",
                    originCountry: $0.selectedCountry?.code ?? "",
                    productID: $0.itemProductID
                )
            }
        )

        onFormReady(form)
    }
}

private extension WooShippingCustomsFormViewModel {
    enum Constants {
        static let minimumValueForRequiredITN = Decimal(2500) // USD
        static let ITNRequiredDestinationForUSPS = ["IR", "SY", "KP", "CU", "SD"]
        static let ITNNonRequiredDestination = "CA"
    }
}

extension WooShippingCustomsFormViewModel.ITNValidationError {
    var message: String {
        switch self {
        case .invalidFormat:
            Localization.itnInvalidFormat
        case .missingForTariffClass:
            Localization.itnRequiredForTariffClass
        case .missingForTotalShipmentValue:
            Localization.itnRequiredForTotalValue
        case .missingForRequiredDestination:
            Localization.itnRequiredForDestination
        }
    }

    private enum Localization {
        static let itnInvalidFormat = NSLocalizedString(
            "wooShippingCustomsFormViewModel.ITNValidationError.invalidFormat.mandatoryAES",
            value: "Please enter a valid ITN in one of these formats: AES X12345678901234, or NOEEI 30.37(a).",
            comment: "Message when the ITN field is invalid in the customs form of a shipping label. " +
            "Doesn't contain X12345678901234 format example."
        )
        static let itnRequiredForTariffClass = NSLocalizedString(
            "wooShippingCustomsFormViewModel.ITNValidationError.missingForTariffClass",
            value: "International Transaction Number is required for shipping items " +
            "valued over $2,500 per tariff number.",
            comment: "Message when the ITN field is missing for a Tariff class in the customs form of a shipping label"
        )
        static let itnRequiredForTotalValue = NSLocalizedString(
            "wooShippingCustomsFormViewModel.ITNValidationError.missingForTotalShipmentValue",
            value: "For shipments over $2,500, you need to obtain a 14-digit " +
            "AES ITN for U.S. export reporting verification.",
            comment: "Message when the ITN field is missing in the customs form of a shipping label for a total shipment value of over $2,500"
        )
        static let itnRequiredForDestination = NSLocalizedString(
            "wooShippingCustomsFormViewModel.ITNValidationError.missingForDestination",
            value: "International Transaction Number is required for shipments to the destination country.",
            comment: "Message when the ITN field is missing in the customs form of a shipping label to the given destination country"
        )
    }
}

enum WooShippingRestrictionType: String, CaseIterable {
    case none
    case quarantine
    case sanitary
    case other
    var name: String {
        switch self {
        case .none:
            return Localization.none
        case .quarantine:
            return Localization.quarantine
        case .sanitary:
            return Localization.sanitary
        case .other:
            return Localization.other

        }
    }
}

extension WooShippingRestrictionType {
    enum Localization {
        static let none = NSLocalizedString("wooShipping.customs.restrictionType.none",
                                                   value: "None",
                                                   comment: "Info label for shipping restriction type none")
        static let quarantine = NSLocalizedString("wooShipping.customs.restrictionType.quarantine",
                                                   value: "Quarantine",
                                                   comment: "Info label for shipping restriction type quarantine")
        static let sanitary = NSLocalizedString("wooShipping.customs.restrictionType.sanitary",
                                                   value: "Sanitary/Phitosanitary Inspection",
                                                   comment: "Info label for shipping restriction type sanitary")
        static let other = NSLocalizedString("wooShipping.customs.restrictionType.other",
                                                   value: "Other",
                                                   comment: "Info label for shipping restriction type other")
    }

    func toFormRestrictionType() -> ShippingLabelCustomsForm.RestrictionType {
        switch self {
        case .none:
            return .none
        case .quarantine:
            return .quarantine
        case .sanitary:
            return .sanitaryOrPhytosanitaryInspection
        case .other:
            return .other
        }
    }
}

enum WooShippingContentType: String, CaseIterable {
    case merchandise
    case gift
    case returnedGoods
    case sample
    case documents
    case other
    var name: String {
        switch self {
        case .merchandise:
            return Localization.merchandise
        case .returnedGoods:
            return Localization.returnedGoods
        case .documents:
            return Localization.documents
        case .gift:
            return Localization.gift
        case .sample:
            return Localization.sample
        case .other:
            return Localization.other
        }
    }
}

extension WooShippingContentType {
    enum Localization {
        static let merchandise = NSLocalizedString("wooShipping.customs.contentType.merchandise",
                                                   value: "Merchandise",
                                                   comment: "Info label for shipping content type merchandise")
        static let returnedGoods = NSLocalizedString("wooShipping.customs.contentType.returnedGoods",
                                                     value: "Returned Goods",
                                                     comment: "Info label for shipping content type returned goods")
        static let documents = NSLocalizedString("wooShipping.customs.contentType.documents",
                                                   value: "Documents",
                                                   comment: "Info label for shipping content type merchandise")
        static let gift = NSLocalizedString("wooShipping.customs.contentType.gift",
                                                   value: "Gift",
                                                   comment: "Info label for shipping content type merchandise")
        static let sample = NSLocalizedString("wooShipping.customs.contentType.sample",
                                                   value: "Sample",
                                                   comment: "Info label for shipping content type merchandise")
        static let other = NSLocalizedString("wooShipping.customs.contentType.other",
                                                   value: "Other...",
                                                   comment: "Info label for shipping content type merchandise")
    }

    func toFormContentsType() -> ShippingLabelCustomsForm.ContentsType {
        switch self {
        case .merchandise:
            return .merchandise
        case .gift:
            return .gift
        case .returnedGoods:
            return .other
        case .sample:
            return .sample
        case .documents:
            return .documents
        case .other:
            return .other
        }
    }
}

enum ITNNumberValidator {
    /// Validates AES/ITN (International Transaction Number) or NOEEI (No EEI) exemption codes
    /// Accepts formats like:
    /// - AES ITN: X12345678901234, AES 12345678901234 or AES ITN: 12345678901234
    /// - NOEEI exemptions: NOEEI 30.36 or NOEEI 30.36(a) or NOEEI 30.36(a)(1)
    /// AES/ITN numbers which are 14 digits long, optionally prefixed with 'X', 'AES', and/or 'ITN'
    /// NOEEI exemption codes in the format "NOEEI 30.XX" with optional subsection letters and numbers
    static func isValid(_ itnNumber: String) -> Bool {
        guard itnNumber.isNotEmpty else {
            return true
        }

        let pattern = "^(?:(?:AES(?!\\S)\\s*(?:ITN:?\\s*)?X?\\d{14})|(?:NOEEI\\s+30\\.\\d{2}(?:\\([a-z]\\)(?:\\(\\d\\))?)?))$"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(itnNumber.startIndex..<itnNumber.endIndex, in: itnNumber)
            return regex.firstMatch(in: itnNumber, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

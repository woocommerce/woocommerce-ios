import SwiftUI
import Yosemite
import Combine
import WooFoundation

final class WooShippingCustomsFormViewModel: ObservableObject {
    @Published var internationalTransactionNumber: String = ""
    @Published var returnToSenderIfNotDelivered: Bool = false

    let onCompletion: (ShippingLabelCustomsForm) -> ()

    @Published var requiredInformationIsEntered: Bool = false

    @Published var contentType: WooShippingContentType = .merchandise
    @Published var restrictionType: WooShippingRestrictionType = .none

    let itnInfoURL = URL(string: "https://pe.usps.com/text/imm/immc5_010.htm")

    private var cancellables = Set<AnyCancellable>()

    init(orderItems: [OrderItem], onCompletion: @escaping (ShippingLabelCustomsForm) -> ()) {
        self.onCompletion = onCompletion

        itemsViewModels = orderItems.map {
            // TODO: Pass the origin country
            WooShippingCustomsItemViewModel(originCountry: WooShippingCustomsCountry(code: "US", name: "United States"),
                                            orderItem: $0)
        }

        listenToItemsRequiredInformationValues()
    }

    @Published var itemsViewModels: [WooShippingCustomsItemViewModel] = []

    func onDismiss() {
        let form = ShippingLabelCustomsForm(packageID: "",
                                            packageName: "",
                                            contentsType: contentType.toFormContentsType(),
                                            contentExplanation: "",
                                            restrictionType: restrictionType.toFormRestrictionType(),
                                            restrictionComments: "",
                                            nonDeliveryOption: returnToSenderIfNotDelivered ? .return : .abandon,
                                            itn: internationalTransactionNumber,
                                            items: itemsViewModels.map {
            ShippingLabelCustomsForm.Item(description: $0.description,
                                          quantity: $0.orderItem.quantity,
                                          value: Double($0.valuePerUnit) ?? 0,
                                          weight: Double($0.weightPerUnit) ?? 0,
                                          hsTariffNumber: $0.isValidTariffNumber ? $0.hsTariffNumber : "",
                                          originCountry: $0.originCountry.name,
                                          productID: $0.orderItem.productID)
            }
        )
        onCompletion(form)
    }
}

private extension WooShippingCustomsFormViewModel {
    func listenToItemsRequiredInformationValues() {
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
                self?.requiredInformationIsEntered = value
            }
            .store(in: &cancellables)
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

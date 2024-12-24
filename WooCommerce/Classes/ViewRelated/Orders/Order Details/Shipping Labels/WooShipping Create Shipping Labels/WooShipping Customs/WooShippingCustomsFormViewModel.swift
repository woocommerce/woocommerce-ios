import SwiftUI

final class WooShippingCustomsFormViewModel: ObservableObject {
    @Published var internationalTransactionNumber: String
    @Published var returnToSenderIfNotDelivered: Bool

    let contentType: WooShippingContentType = .merchandise
    let restrictionType: WooShippingRestrictionType = .none

    let itnInfoURL = URL(string: "https://pe.usps.com/text/imm/immc5_010.htm")

    init(internationalTransactionNumber: String, returnToSenderIfNotDelivered: Bool) {
        self.internationalTransactionNumber = internationalTransactionNumber
        self.returnToSenderIfNotDelivered = returnToSenderIfNotDelivered
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
}

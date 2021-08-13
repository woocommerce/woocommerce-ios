import Foundation
import Yosemite

extension ShippingLabelCustomsForm.ContentsType {
    var localizedName: String {
        switch self {
        case .merchandise:
            return Localization.contentTypeMerchandise
        case .documents:
            return Localization.contentTypeDocuments
        case .gift:
            return Localization.contentTypeGift
        case .sample:
            return Localization.contentTypeSample
        case .other:
            return Localization.contentTypeOther
        }
    }

    private enum Localization {
        static let contentTypeMerchandise = NSLocalizedString("Merchandise",
                                                              comment: "Type Merchandise of content to be declared for the customs form in Shipping Label flow")
        static let contentTypeDocuments = NSLocalizedString("Documents",
                                                            comment: "Type Documents of content to be declared for the customs form in Shipping Label flow")
        static let contentTypeGift = NSLocalizedString("Gift",
                                                       comment: "Type Gift of content to be declared for the customs form in Shipping Label flow")
        static let contentTypeSample = NSLocalizedString("Sample",
                                                         comment: "Type Sample of content to be declared for the customs form in Shipping Label flow")
        static let contentTypeOther = NSLocalizedString("Other",
                                                        comment: "Type Other of content to be declared for the customs form in Shipping Label flow")
    }
}

extension ShippingLabelCustomsForm.RestrictionType {
    var localizedName: String {
        switch self {
        case .none:
            return Localization.restrictionTypeNone
        case .quarantine:
            return Localization.restrictionTypeQuarantine
        case .sanitaryOrPhytosanitaryInspection:
            return Localization.restrictionTypeSanitary
        case .other:
            return Localization.restrictionTypeOther
        }
    }

    private enum Localization {
        static let restrictionTypeNone = NSLocalizedString("None",
                                                           comment: "Restriction type None for contents declared in the customs form for Shipping Label flow")
        static let restrictionTypeQuarantine = NSLocalizedString("Quarantine",
                                                                 comment: "Restriction type Quarantine for contents declared in the " +
                                                                    "customs form for Shipping Label flow")
        static let restrictionTypeSanitary = NSLocalizedString("Sanitary / Phytosanitary Inspection",
                                                               comment: "Restriction type Sanitary / Phytosanitary Inspection for " +
                                                                "contents declared in the customs form for Shipping Label flow")
        static let restrictionTypeOther = NSLocalizedString("Other",
                                                            comment: "Restriction type Other for contents declared in the customs form for Shipping Label flow")
    }
}

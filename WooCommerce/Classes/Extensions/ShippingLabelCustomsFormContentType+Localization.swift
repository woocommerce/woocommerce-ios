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

    enum Localization {
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

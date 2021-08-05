import Foundation
import Codegen

/// Represents customs info for a shipping label package
///
public struct ShippingLabelCustomsForm: Equatable, GeneratedFakeable {
    /// Type of contents to declare with customs.
    public let contentsType: ContentsType

    /// Explanation for contents if of type other, empty otherwise.
    public let contentExplanation: String

    /// Restriction type of contents.
    public let restrictionType: RestrictionType

    /// Details about restriction if of type other, empty otherwise.
    public let restrictionComments: String

    /// Option if delivery fails.
    public let nonDeliveryOption: NonDeliveryOption

    /// Internal Transaction Number (optional).
    public let itn: String?

    /// Items in the package to declare.
    public let items: [Item]
}

// MARK: - Subtypes
//
public extension ShippingLabelCustomsForm {
    /// Types of contents to declare with customs.
    ///
    enum ContentsType: String {
        case merchandise
        case documents
        case gift
        case sample
        case other
    }

    /// Types of restriction of contents to declare with customs.
    ///
    enum RestrictionType: String {
        case none
        case quarantine
        case sanitaryOrPhytosanitaryInspection = "sanitary_phytosanitary_inspection"
        case other
    }

    /// Options if delivery fails.
    ///
    enum NonDeliveryOption: String {
        case `return`
        case abandon
    }

    /// Information about a item to declare with customs.
    ///
    struct Item: Encodable, Equatable, GeneratedFakeable {
        /// Description of item.
        public let description: String

        /// Quantity of item
        public let quantity: Int

        /// Price of item per unit.
        public let value: Double

        /// Weight of item per unit.
        public let weight: Double

        /// HS tariff number, empty if N/A.
        public let hsTariffNumber: String

        /// Origin country code of item.
        public let originCountry: String

        /// Product ID of item.
        public let productID: Int64
    }
}

// MARK: - Codable
//
private extension ShippingLabelCustomsForm.Item {
    enum CodingKeys: String, CodingKey {
        case description
        case quantity
        case value
        case weight
        case hsTariffNumber = "hs_tariff_number"
        case originCountry = "origin_country"
        case productID = "product_id"
    }
}

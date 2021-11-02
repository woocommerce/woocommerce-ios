import Foundation
import Codegen

/// Represents a Product Add-On entity
///
public struct ProductAddOn: Codable, Equatable, GeneratedCopiable, GeneratedFakeable {
    /// Add-on Type.
    ///
    public let type: AddOnType

    /// Add-on display option. Relevant for `multipleChoice` type.
    ///
    public let display: AddOnDisplay

    /// Add-on name.
    ///
    public let name: String

    /// Add-on title format.
    ///
    public let titleFormat: AddOnTitleFormat

    /// Whether or not the description is displayed. (0 false, 1 true)
    ///
    public let descriptionEnabled: Int

    /// Add-on description.
    ///
    public let description: String

    /// Whether or not the customer must choose/complete at least one option from the add-on. (0 false, 1 true)
    ///
    public let required: Int

    /// Display position of the add-on in the group
    ///
    public let position: Int

    /// Whether or not input text is restricted. (0 false, 1 true)
    ///
    public let restrictions: Int

    /// Restrictions on input text.
    ///
    public let restrictionsType: AddOnRestrictionsType

    /// Whether or not price is adjusted (0 false, 1 true)
    ///
    public let adjustPrice: Int

    /// Add-on pricing type.
    ///
    public let priceType: AddOnPriceType

    /// Add-on price, can be empty, not relevant for `heading`, `checkbox` and `multiple_choice` types.
    ///
    public let price: String

    /// Minimum range on customer input. Relevant for `custom_text`, `custom_textarea`, `custom_price` and `input_multiplier` types.
    ///
    public let min: Int

    /// Maximum range on customer input. Relevant for `custom_text`, `custom_textarea`, `custom_price` and `input_multiplier` types.
    ///
    public let max: Int

    /// Options available for the add-on
    ///
    public let options: [ProductAddOnOption]

    public init(type: AddOnType,
                display: AddOnDisplay,
                name: String,
                titleFormat: AddOnTitleFormat,
                descriptionEnabled: Int,
                description: String,
                required: Int,
                position: Int,
                restrictions: Int,
                restrictionsType: AddOnRestrictionsType,
                adjustPrice: Int,
                priceType: AddOnPriceType,
                price: String,
                min: Int,
                max: Int,
                options: [ProductAddOnOption]) {
        self.type = type
        self.display = display
        self.name = name
        self.titleFormat = titleFormat
        self.descriptionEnabled = descriptionEnabled
        self.description = description
        self.required = required
        self.position = position
        self.restrictions = restrictions
        self.restrictionsType = restrictionsType
        self.adjustPrice = adjustPrice
        self.priceType = priceType
        self.price = price
        self.min = min
        self.max = max
        self.options = options
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(AddOnType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.display = try container.decodeIfPresent(AddOnDisplay.self, forKey: .display) ?? .none
        self.titleFormat = try container.decodeIfPresent(AddOnTitleFormat.self, forKey: .titleFormat) ?? .none
        self.restrictionsType = try container.decodeIfPresent(AddOnRestrictionsType.self, forKey: .restrictionsType) ?? .none
        self.priceType = try container.decodeIfPresent(AddOnPriceType.self, forKey: .priceType) ?? .none
        self.price = try container.decodeIfPresent(String.self, forKey: .price) ?? ""
        self.options = try container.decodeIfPresent([ProductAddOnOption].self, forKey: .options) ?? []

        // Heading type, returns these fields as empty strings instead of ints, so we need to fail-safe decode them.
        self.descriptionEnabled = container.failsafeDecodeIfPresent(Int.self, forKey: .descriptionEnabled) ?? 0
        self.required = container.failsafeDecodeIfPresent(Int.self, forKey: .required) ?? 0
        self.position = container.failsafeDecodeIfPresent(Int.self, forKey: .position) ?? 0
        self.restrictions = container.failsafeDecodeIfPresent(Int.self, forKey: .restrictions) ?? 0
        self.adjustPrice = container.failsafeDecodeIfPresent(Int.self, forKey: .adjustPrice) ?? 0
        self.min = container.failsafeDecodeIfPresent(Int.self, forKey: .min) ?? 0
        self.max = container.failsafeDecodeIfPresent(Int.self, forKey: .max) ?? 0
    }
}

// MARK: Coding Keys
//
private extension ProductAddOn {
    enum CodingKeys: String, CodingKey {
        case type
        case display
        case name
        case titleFormat = "title_format"
        case descriptionEnabled = "description_enable"
        case description
        case required
        case position
        case restrictions
        case restrictionsType = "restrictions_type"
        case adjustPrice = "adjust_price"
        case priceType = "price_type"
        case price
        case min
        case max
        case options
    }
}

/// Represents all possible Add-On types.
///
public enum AddOnType: String, Codable, GeneratedFakeable {
    case multipleChoice = "multiple_choice"
    case checkbox
    case customText = "custom_text"
    case customTextArea = "custom_textarea"
    case fileUpload = "file_upload"
    case customPrice = "custom_price"
    case inputMultiplier = "input_multiplier"
    case heading
}

/// Represents all possible Add-On display options.
///
public enum AddOnDisplay: String, Codable, GeneratedFakeable {
    case dropdown = "select"
    case radioButton = "radiobutton"
    case images
    case none = ""
}

/// Represents all possible Add-On title formats.
///
public enum AddOnTitleFormat: String, Codable, GeneratedFakeable {
    case label
    case heading
    case hide
    case none = ""
}

/// Represents all possible Add-On restrictions types.
///
public enum AddOnRestrictionsType: String, Codable, GeneratedFakeable {
    case any_text = "any_text"
    case onlyLetters = "only_letters"
    case onlyNumbers = "only_numbers"
    case onlyLettersNumbers = "only_letters_numbers"
    case email
    case none = ""
}

/// Represents all possible Add-On pricing types.
///
public enum AddOnPriceType: String, Codable, GeneratedFakeable {
    case flatFee = "flat_fee"
    case quantityBased = "quantity_based"
    case percentageBased = "percentage_based"
    case none = ""
}

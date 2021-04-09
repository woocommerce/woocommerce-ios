import Foundation
import Storage
import Networking

extension Storage.ProductAddOn: ReadOnlyConvertible {
    public func update(with entity: Yosemite.ProductAddOn) {
        type = entity.type.rawValue
        display = entity.display.rawValue
        name = entity.name
        titleFormat = entity.titleFormat.rawValue
        descriptionEnabled = entity.descriptionEnabled
        descriptions = entity.description
        required = entity.required
        position = entity.position
        restrictions = entity.restrictions
        restrictionsType = entity.restrictionsType.rawValue
        adjustPrice = entity.adjustPrice
        priceType = entity.priceType.rawValue
        price = entity.price
        min = entity.min
        max = entity.max
    }

    public func toReadOnly() -> Yosemite.ProductAddOn {
        ProductAddOn(type: AddOnType(rawValue: type) ?? .checkbox,
                     display: AddOnDisplay(rawValue: display) ?? .dropdown,
                     name: name,
                     titleFormat: AddOnTitleFormat(rawValue: titleFormat) ?? .label,
                     descriptionEnabled: descriptionEnabled,
                     description: descriptions,
                     required: required,
                     position: position,
                     restrictions: restrictions,
                     restrictionsType: AddOnRestrictionsType(rawValue: restrictionsType) ?? .any_text,
                     adjustPrice: adjustPrice,
                     priceType: AddOnPriceType(rawValue: priceType) ?? .flatFee,
                     price: price,
                     min: min,
                     max: max,
                     options: options?.map { $0.toReadOnly() } ?? [] )
    }
}

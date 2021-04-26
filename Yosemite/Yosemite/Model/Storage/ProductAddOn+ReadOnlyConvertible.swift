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
        required = Int64(entity.required)
        position = Int64(entity.position)
        restrictions = Int64(entity.restrictions)
        restrictionsType = entity.restrictionsType.rawValue
        adjustPrice = Int64(entity.adjustPrice)
        priceType = entity.priceType.rawValue
        price = entity.price
        min = Int64(entity.min)
        max = Int64(entity.max)
    }

    public func toReadOnly() -> Yosemite.ProductAddOn {
        let optionsArray: [StorageProductAddOnOption] = options?.toArray() ?? []
        return ProductAddOn(type: AddOnType(rawValue: type) ?? .checkbox,
                            display: AddOnDisplay(rawValue: display) ?? .dropdown,
                            name: name,
                            titleFormat: AddOnTitleFormat(rawValue: titleFormat) ?? .label,
                            descriptionEnabled: descriptionEnabled,
                            description: descriptions,
                            required: Int(required),
                            position: Int(position),
                            restrictions: Int(restrictions),
                            restrictionsType: AddOnRestrictionsType(rawValue: restrictionsType) ?? .any_text,
                            adjustPrice: Int(adjustPrice),
                            priceType: AddOnPriceType(rawValue: priceType) ?? .flatFee,
                            price: price,
                            min: Int(min),
                            max: Int(max),
                            options: optionsArray.map { $0.toReadOnly() } )
    }
}

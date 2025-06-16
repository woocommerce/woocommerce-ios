import Foundation
import Storage
import Networking

extension Storage.ProductAddOnOption: ReadOnlyConvertible {
    public func update(with entity: Yosemite.ProductAddOnOption) {
        label = entity.label
        price = entity.price
        imageID = entity.imageID
        priceType = entity.priceType?.rawValue
    }

    public func toReadOnly() -> Yosemite.ProductAddOnOption {
        ProductAddOnOption(label: label,
                           price: price,
                           priceType: AddOnPriceType(rawValue: priceType ?? ""),
                           imageID: imageID)
    }
}

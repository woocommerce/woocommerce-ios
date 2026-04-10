import Foundation
import Storage

// MARK: - Storage.BookingProductInfo: ReadOnlyConvertible
//
extension Storage.BookingProductInfo: ReadOnlyConvertible {
    public func update(with productInfo: Yosemite.BookingProductInfo) {
        name = productInfo.name
    }

    public func toReadOnly() -> Yosemite.BookingProductInfo {
        return .init(name: name ?? "")
    }
}

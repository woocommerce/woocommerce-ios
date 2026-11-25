import Foundation
import Yosemite

class MockPointOfSaleBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    var errorToThrow: PointOfSaleBarcodeScanError?

    func getItem(barcode: String) async throws(PointOfSaleBarcodeScanError) -> POSItem {
        if let error = errorToThrow {
            throw error
        }

        return .simpleProduct(POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: 1),
            name: "Scanned Item",
            formattedPrice: "$10.00",
            productID: 1,
            price: "10.00",
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: ""
        ))
    }
}

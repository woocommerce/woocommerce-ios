import Foundation
import Yosemite

struct MockPointOfSaleBarcodeScanService: PointOfSaleBarcodeScanServiceProtocol {
    func getItem(barcode: String) async throws -> POSItem {
        return .simpleProduct(POSSimpleProduct(
            id: UUID(),
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
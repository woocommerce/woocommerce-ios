import Foundation
import enum Yosemite.POSItem
import struct Yosemite.POSSimpleProduct
import struct Yosemite.POSVariableParentProduct
import struct Yosemite.POSItemIdentifier

enum PrototypeCatalog {
    static let smallCafe: [POSItem] = [
        makeSimple(id: 1, name: "Espresso", price: "3.50"),
        makeSimple(id: 2, name: "Latte", price: "5.00"),
        makeSimple(id: 3, name: "Cappuccino", price: "4.75"),
        makeSimple(id: 4, name: "Croissant", price: "3.25"),
        makeSimple(id: 5, name: "Blueberry Muffin", price: "3.50"),
    ]

    static let busyRetail: [POSItem] = {
        var items: [POSItem] = []
        let names = ["Wireless Headphones", "USB-C Cable", "Phone Case", "Screen Protector",
                     "Bluetooth Speaker", "Laptop Stand", "Mechanical Keyboard", "Mouse Pad",
                     "Webcam HD", "Ring Light", "Desk Lamp", "Cable Organizer",
                     "Power Bank", "Car Charger", "Wall Adapter", "HDMI Cable",
                     "Ethernet Adapter", "Memory Card 64GB", "USB Flash Drive", "Portable SSD"]
        let prices = ["12.99", "8.99", "15.00", "9.99", "29.99", "34.50", "79.99", "14.99",
                      "49.99", "24.99", "19.99", "7.50", "22.00", "11.99", "16.99", "10.00",
                      "18.50", "13.99", "21.00", "89.99"]
        for (index, name) in names.enumerated() {
            items.append(makeSimple(id: Int64(index + 100), name: name, price: prices[index]))
        }
        return items
    }()

    static let phoneMinimal: [POSItem] = [
        makeSimple(id: 1, name: "Coffee", price: "4.00"),
        makeSimple(id: 2, name: "Tea", price: "3.50"),
        makeSimple(id: 3, name: "Cookie", price: "2.50"),
    ]

    private static func makeSimple(id: Int64, name: String, price: String) -> POSItem {
        .simpleProduct(POSSimpleProduct(
            id: POSItemIdentifier(underlyingType: .product, itemID: id),
            name: name,
            formattedPrice: "$\(price)",
            productID: id,
            price: price,
            manageStock: false,
            stockQuantity: nil,
            stockStatusKey: "instock"
        ))
    }
}

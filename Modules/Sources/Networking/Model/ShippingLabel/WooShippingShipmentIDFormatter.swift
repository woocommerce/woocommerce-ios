import Foundation

enum WooShippingShipmentIDFormatter {
    /// Turns numeric shipment ID into formatted as `shipment_<id>`
    /// - Parameter shipmentID: numeric shipment id
    /// - Returns: formated id string
    static func formattedShipmentID(_ shipmentID: String) -> String {
        return isArgumentIDValid(shipmentID) ?
        Values.shipmentIDPrefix + shipmentID :
        shipmentID
    }
}

private extension WooShippingShipmentIDFormatter {
    private enum Values {
        static let shipmentIDPrefix = "shipment_"
    }

    /// Make sure we are formatting incoming numeric ID string
    private static func isArgumentIDValid(_ argumentID: String) -> Bool {
        return Int(argumentID) != nil
    }
}

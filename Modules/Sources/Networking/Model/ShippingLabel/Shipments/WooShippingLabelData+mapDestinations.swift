import Foundation

extension WooShippingLabelData {
    static func mapDestinations(
        _ destinations: WooShippingLabelDestinations,
        into labels: [ShippingLabel]
    ) -> [ShippingLabel] {
        return labels.map { label in
            guard
                let shipmentID = label.shipmentID,
                let destinationAddress = destinations[
                    WooShippingShipmentIDFormatter.formattedShipmentID(shipmentID)
                ] ?? destinations[shipmentID] /// Fallback for ids previously submitted without `shipment_<id>` formatting
            else {
                return label
            }

            return label.copy(destinationAddress: destinationAddress.toShippingLabelAddress())
        }
    }
}

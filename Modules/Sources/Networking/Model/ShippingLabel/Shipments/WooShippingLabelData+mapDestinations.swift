import Foundation

extension WooShippingLabelData {
    static func mapAddresses(
        origins: WooShippingLabelAddressMap?,
        destinations: WooShippingLabelAddressMap?,
        into labels: [ShippingLabel]
    ) -> [ShippingLabel] {
        return labels.map { label in
            guard let shipmentID = label.shipmentID else {
                return label
            }

            let formattedID = WooShippingShipmentIDFormatter.formattedShipmentID(shipmentID)
            let originAddress = origins?[formattedID] ?? origins?[shipmentID]
            let destinationAddress = destinations?[formattedID] ?? destinations?[shipmentID]

            return label.copy(
                originAddress: originAddress?.toShippingLabelAddress() ?? .copy,
                destinationAddress: destinationAddress?.toShippingLabelAddress() ?? .copy
            )
        }
    }

    static func formattedShipmentIDFromArrayIndex(_ index: Int) -> String {
        /// ID indexing starts from `1`. So the ID would be the index incremented by `1`.
        return WooShippingShipmentIDFormatter.formattedShipmentID(
            String(index + 1)
        )
    }
}

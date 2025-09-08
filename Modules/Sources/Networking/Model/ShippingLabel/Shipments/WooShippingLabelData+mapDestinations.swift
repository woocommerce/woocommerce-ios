import Foundation

extension WooShippingLabelData {
    static func mapAddresses(
        origins: WooShippingLabelAddressMap?,
        destinations: WooShippingLabelAddressMap?,
        hazmatSelections: WooShippingHazmatMap?,
        into labels: [ShippingLabel]
    ) -> [ShippingLabel] {
        return labels.map { label in
            guard let shipmentID = label.shipmentID else {
                return label
            }

            let formattedID = WooShippingShipmentIDFormatter.formattedShipmentID(shipmentID)
            let originAddress = origins?[formattedID] ?? origins?[shipmentID]
            let destinationAddress = destinations?[formattedID] ?? destinations?[shipmentID]
            let hazmat = hazmatSelections?[formattedID] ?? hazmatSelections?[shipmentID]

            return label.copy(
                originAddress: originAddress?.toShippingLabelAddress() ?? .copy,
                destinationAddress: destinationAddress?.toShippingLabelAddress() ?? .copy,
                hazmatCategory: hazmat?.category
            )
        }
    }
}

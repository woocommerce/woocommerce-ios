/// Split shipments availability for standard (non-CIAB) sites.
///
struct StandardShipmentSplittingProvider: ShipmentSplittingProviding {
    let isSplitShipmentsEnabled = true
}

/// Split shipments availability for CIAB sites.
///
struct CIABShipmentSplittingProvider: ShipmentSplittingProviding {
    let isSplitShipmentsEnabled = false
}

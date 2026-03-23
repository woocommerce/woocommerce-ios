/// Provides whether split shipments are available on the current site.
///
/// Standard sites allow it; CIAB sites do not.
///
protocol ShipmentSplittingProviding {
    var isSplitShipmentsEnabled: Bool { get }
}

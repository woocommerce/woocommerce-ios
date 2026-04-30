import Foundation

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    init(unit: UnitLength, initial: ParcelDimensions? = nil) {
        self.unit = unit
        self.dimensions = initial ?? Self.defaultDimensions(for: unit)
    }

    var dimensionsInMeters: SIMD3<Float> {
        dimensions.toMeters(unit: unit)
    }

    var confirmedDimensions: ParcelDimensions { dimensions }

    var dimensionsLabel: String {
        let format = "L: %.1f  W: %.1f  H: %.1f %@"
        return String(format: format,
                      dimensions.length,
                      dimensions.width,
                      dimensions.height,
                      unit.symbol)
    }

    func update(fromMeters meters: SIMD3<Float>) {
        dimensions = ParcelDimensions.fromMeters(meters, unit: unit)
    }

    private static func defaultDimensions(for unit: UnitLength) -> ParcelDimensions {
        unit == .inches
            ? ParcelDimensions(length: 8.0, width: 6.0, height: 4.0)
            : ParcelDimensions(length: 20.0, width: 15.0, height: 10.0)
    }
}

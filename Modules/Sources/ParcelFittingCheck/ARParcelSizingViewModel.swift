import Foundation

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    init(unit: UnitLength, initial: ParcelDimensions? = nil) {
        self.unit = unit
        self.dimensions = initial ?? .defaultDimensions(for: unit)
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

}

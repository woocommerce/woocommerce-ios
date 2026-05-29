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
        dimensions.formattedWithLabels(unit: unit)
    }

    func update(fromMeters meters: SIMD3<Float>) {
        dimensions = ParcelDimensions.fromMeters(meters, unit: unit)
    }

    func resetToDefaults() {
        dimensions = .defaultDimensions(for: unit)
    }
}

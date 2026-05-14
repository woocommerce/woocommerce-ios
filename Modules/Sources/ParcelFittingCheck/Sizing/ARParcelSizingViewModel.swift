import Foundation

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    private(set) var resizeCount: Int = 0
    private(set) var rotateCount: Int = 0
    private(set) var resetCount: Int = 0
    private(set) var arReadyTime: Date?

    init(unit: UnitLength, initial: ParcelDimensions? = nil) {
        self.unit = unit
        self.dimensions = initial ?? .defaultDimensions(for: unit)
    }

    func recordGestureCompleted(mode: TwoFingerCuboidGestureRecognizer.Mode) {
        switch mode {
        case .resize: resizeCount += 1
        case .rotate: rotateCount += 1
        case .undecided: break
        }
    }

    func recordReset() {
        resetCount += 1
    }

    func recordARReady() {
        if arReadyTime == nil {
            arReadyTime = Date()
        }
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

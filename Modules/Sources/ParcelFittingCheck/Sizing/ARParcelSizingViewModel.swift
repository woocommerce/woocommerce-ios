import Foundation
import EventHorizonSDK

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    private(set) var resizeCount: Int = 0
    private(set) var rotateCount: Int = 0
    private(set) var resetCount: Int = 0
    private(set) var arReadyTime: Date?
    private(set) var hasTrackedPlacement: Bool = false

    private let analytics: ParcelFittingAnalyticsTracking

    init(unit: UnitLength, initial: ParcelDimensions? = nil, analytics: ParcelFittingAnalyticsTracking) {
        self.unit = unit
        self.dimensions = initial ?? .defaultDimensions(for: unit)
        self.analytics = analytics
    }

    func recordGestureCompleted(mode: TwoFingerTracker.Mode) {
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

    func trackBoxPlaced() {
        guard !hasTrackedPlacement else { return }
        hasTrackedPlacement = true
        let elapsed = arReadyTime.map { Int(Date().timeIntervalSince($0)) } ?? 0
        analytics.track(Event.arfittingBoxPlaced(timeToPlace: elapsed))
    }

    func trackSizingCompleted() {
        let cm = dimensions.toCentimeters(from: unit)
        analytics.track(Event.arfittingSizingCompleted(
            lengthCm: cm.length,
            widthCm: cm.width,
            heightCm: cm.height,
            resizeCount: resizeCount,
            rotateCount: rotateCount,
            resetCount: resetCount
        ))
    }

    func trackSizingCanceled(hadPlacedBox: Bool, arReady: Bool) {
        analytics.track(Event.arfittingSizingCanceled(
            hadPlacedBox: hadPlacedBox,
            arReady: arReady,
            resizeCount: resizeCount,
            rotateCount: rotateCount,
            resetCount: resetCount
        ))
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

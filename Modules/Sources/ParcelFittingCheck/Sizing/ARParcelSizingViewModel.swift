import Foundation
import EventHorizonSDK

enum ARPhase: Equatable {
    case detecting
    case awaitingTap
    case placed(hintsVisible: Bool)
}

@Observable
final class ARParcelSizingViewModel {
    let unit: UnitLength
    var dimensions: ParcelDimensions

    private(set) var resizeCount: Int = 0
    private(set) var rotateCount: Int = 0
    private(set) var resetCount: Int = 0
    private(set) var arReadyTime: Date?
    private(set) var hasTrackedPlacement: Bool = false
    private(set) var hintsVisible: Bool = false

    private var hasSeenHints: Bool
    private let defaults: UserDefaults
    private let analytics: ParcelFittingAnalyticsTracking

    init(unit: UnitLength,
         initial: ParcelDimensions? = nil,
         analytics: ParcelFittingAnalyticsTracking,
         defaults: UserDefaults = .standard) {
        self.unit = unit
        self.dimensions = initial ?? .defaultDimensions(for: unit)
        self.analytics = analytics
        self.defaults = defaults
        self.hasSeenHints = defaults.bool(forKey: Constants.hintsSeenKey)
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
        let elapsed = arReadyTime.map { Int(Date().timeIntervalSince($0) * 1000) } ?? 0
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

    var dimensionsLabel: String {
        dimensions.formattedWithLabels(unit: unit)
    }

    func update(fromMeters meters: SIMD3<Float>) {
        dimensions = ParcelDimensions.fromMeters(meters, unit: unit)
    }

    func resetToDefaults() {
        dimensions = .defaultDimensions(for: unit)
    }

    func onBoxPlaced() {
        hintsVisible = !hasSeenHints
    }

    func dismissHints() {
        hintsVisible = false
        hasSeenHints = true
        defaults.set(true, forKey: Constants.hintsSeenKey)
    }

    func showHints() {
        hintsVisible = true
    }

    enum Constants {
        static let hintsSeenKey = "parcelFitting.coachingHintsDismissed"
    }
}

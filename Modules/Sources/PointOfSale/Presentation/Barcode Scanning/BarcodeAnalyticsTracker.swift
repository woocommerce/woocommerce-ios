import Foundation
import UIKit
import struct WooFoundation.WooAnalyticsEvent

// MARK: - VoiceOver State Provider

/// Protocol for providing VoiceOver state, enabling testable VoiceOver detection
protocol VoiceOverStateProvider {
    var isVoiceOverRunning: Bool { get }
}

/// System implementation of VoiceOverStateProvider that uses UIAccessibility
struct SystemVoiceOverStateProvider: VoiceOverStateProvider {
    var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }
}

// MARK: - Analytics Tracker

/// Shared analytics tracking for barcode scanning operations.
/// Used by both GameControllerBarcodeObserver and UIKitBarcodeObserver to ensure consistent analytics.
final class BarcodeAnalyticsTracker {

    private let analytics: POSAnalyticsProviding

    init(analytics: POSAnalyticsProviding) {
        self.analytics = analytics
    }

    /// Tracks analytics events for barcode scanning results.
    /// - Parameter result: The result of the barcode scanning operation
    func track(result: HIDBarcodeParserResult) {
        switch result {
        case .success(let barcode, let scanDurationMs):
            analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningSuccess(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: barcode.count
                )
            )
        case .failure(let error, let scanDurationMs):
            analytics.track(
                event: WooAnalyticsEvent.PointOfSale.barcodeScanningFailed(
                    scanDurationMs: scanDurationMs,
                    barcodeLength: error.barcode.count,
                    failReason: error.analyticsReason
                )
            )
        }
    }
}

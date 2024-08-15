import Foundation

/// This class is copied from the Tacks Library and it is adapted for the Woo Watch App.
/// This should be removed/replaced when the Tracks Library properly supports watchOS.
///

public protocol CrashLoggingDataProvider {
    var sentryDSN: String { get }
    var userHasOptedOut: Bool { get }
    var buildType: String { get }
    var currentUser: TracksUser? { get }
    var additionalUserData: [String: Any] { get }
    var errorEventsSamplingRate: Double { get }
    var shouldEnableAutomaticSessionTracking: Bool { get }
    var performanceTracking: PerformanceTracking { get }
    /// Whether app hang are captured.
    var enableAppHangTracking: Bool { get }
    /// Whether HTTP client errors are captured.
    var enableCaptureFailedRequests: Bool { get }
}

/// Default implementations of common protocol properties
public extension CrashLoggingDataProvider {

    var additionalUserData: [String: Any] {
        return [:]
    }

    var shouldEnableAutomaticSessionTracking: Bool {
        return false
    }

    /// Performance tracking is disabled by default to avoid accidentally logging what could be a significant number of extra events
    /// and blow up our events budget.
    var performanceTracking: PerformanceTracking { .disabled }

    var enableAutoPerformanceTracking: Bool {
        switch performanceTracking {
        case .enabled: return true
        case .disabled: return false
        }
    }

    var tracesSampler: PerformanceTracking.Sampler {
        guard case .enabled(let config) = performanceTracking else { return { 0.0 } }
        return config.sampler
    }

    var tracesSampleRate: Double {
        guard case .enabled(let config) = performanceTracking else { return 0.0 }
        return config.sampleRate
    }

    var profilingRate: Double {
        guard case .enabled(let config) = performanceTracking else { return 0.0 }
        return config.profilingRate
    }

    var enableUIViewControllerTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackViewControllers
    }

    var enableNetworkTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackNetwork
    }

    var enableFileIOTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackFileIO
    }

    var enableCoreDataTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackCoreData
    }

    var enableUserInteractionTracing: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackUserInteraction
    }

    /// App hang tracking is disabled by default to avoid unexpected events being tracked.
    var enableAppHangTracking: Bool {
        return false
    }

    /// HTTP client errors are disabled by default to avoid unexpected events being tracked.
    var enableCaptureFailedRequests: Bool {
        return false
    }

    var errorEventsSamplingRate: Double {
        return 1.0
    }
}

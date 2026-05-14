import EventHorizonSDK

public protocol ParcelFittingAnalyticsTracking {
    func track(_ event: Event)
}

public struct NoOpParcelFittingAnalytics: ParcelFittingAnalyticsTracking {
    public init() {}
    public func track(_ event: Event) {}
}

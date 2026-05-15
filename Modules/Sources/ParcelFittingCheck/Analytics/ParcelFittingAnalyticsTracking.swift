@_exported import EventHorizonSDK

public protocol ParcelFittingAnalyticsTracking {
    func track(_ event: Event)
}

#if DEBUG
public struct NoOpParcelFittingAnalytics: ParcelFittingAnalyticsTracking {
    public init() {}
    public func track(_ event: Event) {}
}
#endif

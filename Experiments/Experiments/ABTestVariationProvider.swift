import AutomatticTracks

/// For getting the variation of a `ABTest`
public protocol ABTestVariationProvider {
    /// Returns the `Variation` for the provided `ABTest`
    func variation(for abTest: ABTest) -> Variation
}

/// Default implementation of `ABTestVariationProvider`
public struct DefaultABTestVariationProvider: ABTestVariationProvider {
    public init() { }

    public func variation(for abTest: ABTest) -> Variation {
        abTest.variation ?? .control
    }
}

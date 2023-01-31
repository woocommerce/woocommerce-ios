import protocol Experiments.ABTestVariationProvider
import enum Experiments.ABTest
import enum AutomatticTracks.Variation

final class MockABTestVariationProvider: ABTestVariationProvider {
    var mockVariationValue: Variation!

    func variation(for abTest: ABTest) -> Variation {
        mockVariationValue
    }
}

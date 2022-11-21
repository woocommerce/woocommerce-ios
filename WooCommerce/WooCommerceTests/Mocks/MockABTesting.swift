import Foundation
import enum AutomatticTracks.Variation
import enum Experiments.ABTest

struct MockABTesting {
    /// Sets the provided A/B Test variation in `UserDefaults`, to mock a given experiment assignment
    ///
    static func setVariation(_ variation: AutomatticTracks.Variation, for experiment: ABTest) {
        let newVariation: String?
        switch variation {
        case .control:
            newVariation = "control"
        case .treatment(let type):
            newVariation = type ?? "treatment"
        }

        let assignment = [experiment.rawValue: newVariation]
        UserDefaults.standard.setValue(assignment, forKey: "ab-testing-assignments")
    }
}

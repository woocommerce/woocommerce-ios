import AutomatticTracks

/// ABTest adds A/B testing experiments and runs the tests based on their variations from the ExPlat service.
///
public enum ABTest: String, CaseIterable {
    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null

    /// Returns a variation for the given experiment
    var variation: Variation {
        return ExPlat.shared?.experiment(self.rawValue) ?? .control
    }
}

public extension ABTest {
    /// Start the AB Testing platform if any experiment exists
    ///
    static func start() {
        guard ABTest.allCases.count > 1 else {
            return
        }

        let experimentNames = ABTest.allCases.filter { $0 != .null }.map { $0.rawValue }
        ExPlat.shared?.register(experiments: experimentNames)

        ExPlat.shared?.refresh()
    }
}

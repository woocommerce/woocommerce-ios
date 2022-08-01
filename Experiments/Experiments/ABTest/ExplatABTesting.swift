import AutomatticTracks

struct ExplatABTesting: Experiments.ABTesting {
    func start() {
        guard ABTest.allCases.count > 1 else {
            return
        }

        let experimentNames = ABTest.allCases.map { $0.rawValue }
        ExPlat.shared?.register(experiments: experimentNames)

        ExPlat.shared?.refresh()
    }

    func refresh() async {
        ExPlat.shared?.refresh()
    }

    func variation(for test: ABTest) -> Variation {
        ExPlat.shared?.experiment(test.rawValue) ?? .control
    }

    func logEvent(_ event: ABTestEvent) {
        // no-op
    }
}

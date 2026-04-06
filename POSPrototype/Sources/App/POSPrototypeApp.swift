import SwiftUI

@main
struct POSPrototypeApp: App {
    private let scenarios: [any POSPrototypeScenario] = [
        SmallCafeScenario(),
    ]

    var body: some Scene {
        WindowGroup {
            ScenarioPickerView(scenarios: scenarios)
        }
    }
}

import SwiftUI

@main
struct POSPrototypeApp: App {
    private let scenarios: [any POSPrototypeScenario] = [
        SimpleStoreScenario(),
        LargeCatalogScenario(),
        NoReaderScenario(),
        PhoneLayoutScenario(),
    ]

    var body: some Scene {
        WindowGroup {
            ScenarioPickerView(scenarios: scenarios)
        }
    }
}

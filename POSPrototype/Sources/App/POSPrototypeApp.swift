import SwiftUI

@main
struct POSPrototypeApp: App {
    init() {
        // Enable auto-restore by default
        if !UserDefaults.standard.bool(forKey: "prototype.hasLaunched") {
            PrototypeStateRestoration.isAutoRestoreEnabled = true
            UserDefaults.standard.set(true, forKey: "prototype.hasLaunched")
        }
    }

    static let allScenarios: [any POSPrototypeScenario] = [
        SimpleStoreScenario(),
        LargeCatalogScenario(),
        NoReaderScenario(),
        PhoneLayoutScenario(),
    ]

    var body: some Scene {
        WindowGroup {
            ScenarioPickerView(scenarios: Self.allScenarios)
        }
    }
}

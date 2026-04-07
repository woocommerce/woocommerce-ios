import SwiftUI
import Inject

@main
struct POSPrototypeApp: App {
    init() {
        // Point Inject library to InjectionNext's bundle path instead of InjectionIII's
        InjectConfiguration.bundlePath = "/Applications/InjectionNext.app/Contents/Resources/"
    }

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

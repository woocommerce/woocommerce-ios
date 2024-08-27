import SwiftUI

/// Environment AppBindings setup
///
private enum AppBindingsKey: EnvironmentKey {
    static let defaultValue: AppBindings = AppBindings()
}

extension EnvironmentValues {
    var appBindings: AppBindings {
        get {
            self[AppBindingsKey.self]
        }
        set {
            self[AppBindingsKey.self] = newValue
        }
    }
}

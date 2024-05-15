import SwiftUI

/// Environment dependencies setup
///
private enum DependenciesKey: EnvironmentKey {
    static let defaultValue: WatchDependencies = WatchDependencies(storeID: .zero, credentials: .init(authToken: ""))
}

extension EnvironmentValues {
    var dependencies: WatchDependencies {
        get {
            self[DependenciesKey.self]
        }
        set {
            self[DependenciesKey.self] = newValue
        }
    }
}

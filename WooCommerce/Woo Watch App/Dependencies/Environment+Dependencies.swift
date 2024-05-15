import SwiftUI

/// Environment dependencies setup
///
private enum DependenciesKey: EnvironmentKey {
    static let defaultValue: WatchDependencies = .fake()
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

extension WatchDependencies {
    /// Fake object, useful as a default value and for previews.
    ///
    static func fake() -> Self {
        .init(storeID: .zero, credentials: .init(authToken: ""))
    }
}

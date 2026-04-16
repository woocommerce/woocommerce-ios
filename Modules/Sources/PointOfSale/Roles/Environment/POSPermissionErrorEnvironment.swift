import SwiftUI

/// Observable object for reporting POS permission errors from any view in the hierarchy.
/// The entry point view observes this and shows the permission error alert.
@MainActor
public final class POSPermissionErrorReporter: ObservableObject {
    @Published var currentError: Error?

    /// Reports a permission error (403). The entry point view will show an alert.
    func reportPermissionError(_ error: Error) {
        currentError = error
    }
}

struct POSPermissionErrorReporterKey: EnvironmentKey {
    static let defaultValue = POSPermissionErrorReporter()
}

extension EnvironmentValues {
    var posPermissionErrorReporter: POSPermissionErrorReporter {
        get { self[POSPermissionErrorReporterKey.self] }
        set { self[POSPermissionErrorReporterKey.self] = newValue }
    }
}

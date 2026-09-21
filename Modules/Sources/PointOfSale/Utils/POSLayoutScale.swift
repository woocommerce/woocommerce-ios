import SwiftUI

enum POSLayoutScale {
    case regular
    case compact
}

private struct POSLayoutScaleKey: EnvironmentKey {
    static let defaultValue: POSLayoutScale = .regular
}

extension EnvironmentValues {
    var posLayoutScale: POSLayoutScale {
        get { self[POSLayoutScaleKey.self] }
        set { self[POSLayoutScaleKey.self] = newValue }
    }
}

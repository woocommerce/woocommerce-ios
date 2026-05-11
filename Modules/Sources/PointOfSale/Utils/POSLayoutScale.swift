import SwiftUI

enum POSLayoutScale {
    case tablet
    case phone
}

private struct POSLayoutScaleKey: EnvironmentKey {
    static let defaultValue: POSLayoutScale = .tablet
}

extension EnvironmentValues {
    var posLayoutScale: POSLayoutScale {
        get { self[POSLayoutScaleKey.self] }
        set { self[POSLayoutScaleKey.self] = newValue }
    }
}

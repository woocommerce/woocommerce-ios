import SwiftUI

private struct POSHeaderLeadingContentKey: EnvironmentKey {
    static var defaultValue: AnyView? { nil }
}

extension EnvironmentValues {
    var posHeaderLeadingContent: AnyView? {
        get { self[POSHeaderLeadingContentKey.self] }
        set { self[POSHeaderLeadingContentKey.self] = newValue }
    }
}

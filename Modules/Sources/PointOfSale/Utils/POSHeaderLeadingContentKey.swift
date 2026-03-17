import SwiftUI

struct POSHeaderLeadingContentKey: EnvironmentKey {
    static let defaultValue: AnyView? = nil
}

extension EnvironmentValues {
    var posHeaderLeadingContent: AnyView? {
        get { self[POSHeaderLeadingContentKey.self] }
        set { self[POSHeaderLeadingContentKey.self] = newValue }
    }
}

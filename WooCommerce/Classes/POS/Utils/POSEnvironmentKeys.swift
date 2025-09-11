import Foundation
import SwiftUI

struct SiteTimezoneKey: EnvironmentKey {
    static let defaultValue: TimeZone = .current
}

extension EnvironmentValues {
    var siteTimezone: TimeZone {
        get { self[SiteTimezoneKey.self] }
        set { self[SiteTimezoneKey.self] = newValue }
    }
}

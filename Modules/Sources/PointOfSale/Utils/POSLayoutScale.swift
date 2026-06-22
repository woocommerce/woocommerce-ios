import SwiftUI
import protocol WooFoundation.WooAnalyticsEventPropertyType

enum POSLayoutScale {
    case tablet
    case phone

    static let defaultAnalyticsValue = "regular"

    var analyticsValue: String {
        switch self {
        case .tablet:
            return Self.defaultAnalyticsValue
        case .phone:
            return "compact"
        }
    }
}

extension Optional where Wrapped == POSLayoutScale {
    var analyticsValue: String {
        self?.analyticsValue ?? POSLayoutScale.defaultAnalyticsValue
    }

    var analyticsProperties: [String: WooAnalyticsEventPropertyType] {
        ["pos_layout": analyticsValue]
    }
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

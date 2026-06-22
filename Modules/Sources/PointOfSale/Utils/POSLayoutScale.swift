import SwiftUI
import protocol WooFoundation.WooAnalyticsEventPropertyType

enum POSLayoutScale {
    case tablet
    case phone

    var analyticsValue: String {
        switch self {
        case .tablet:
            return "regular"
        case .phone:
            return "compact"
        }
    }
}

extension Optional where Wrapped == POSLayoutScale {
    var analyticsProperties: [String: WooAnalyticsEventPropertyType] {
        guard let self else {
            return [:]
        }
        return ["pos_layout": self.analyticsValue]
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

import SwiftUI
import protocol WooFoundation.WooAnalyticsEventPropertyType

public enum POSAnalyticsLayout: String {
    case regular
    case compact

    var analyticsProperties: [String: WooAnalyticsEventPropertyType] {
        ["pos_layout": rawValue]
    }
}

enum POSLayoutScale {
    case tablet
    case phone

    var analyticsLayout: POSAnalyticsLayout {
        switch self {
        case .tablet:
            return .regular
        case .phone:
            return .compact
        }
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

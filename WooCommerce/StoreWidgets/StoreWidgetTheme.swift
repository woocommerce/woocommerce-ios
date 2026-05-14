import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

/// User-selectable color scheme for the home-screen Store Stats widget. Exposed as an
/// AppIntent parameter via `StoreStatsConfigurationIntent.theme` and propagated to views
/// through the `\.storeWidgetTheme` SwiftUI environment.
///
enum StoreWidgetTheme: String {
    /// Brand-purple background with white text and white logo.
    case brandPurple
    /// System widget background (adapts to light/dark) with system text colors and a
    /// brand-purple-tinted logo.
    case sameAsSystem
}

// MARK: - AppEnum conformance

// Gated to platforms that ship AppIntents (iOS 16+, watchOS 10+, etc). The
// `WatchWidgetsExtension` target deploys to watchOS 9, so the conformance is excluded
// from that build slice — the environment-driven view styling still works there.
#if canImport(AppIntents)
@available(iOS 16.0, watchOS 10.0, macOS 13.0, *)
extension StoreWidgetTheme: AppEnum {
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Theme")
    }

    static var caseDisplayRepresentations: [StoreWidgetTheme: DisplayRepresentation] {
        [
            .brandPurple: DisplayRepresentation(title: "Brand Purple"),
            .sameAsSystem: DisplayRepresentation(title: "Same as system")
        ]
    }
}
#endif

// MARK: - Style tokens

extension StoreWidgetTheme {
    /// Primary text color — store name, big metric values, body text.
    var primaryTextColor: Color {
        switch self {
        case .brandPurple: return Color(.white)
        case .sameAsSystem: return Color.primary
        }
    }

    /// Secondary text color — date range, "As of …" line, metric titles.
    var secondaryTextColor: Color {
        switch self {
        case .brandPurple:
            #if os(watchOS)
            return Color.white.opacity(0.7)
            #else
            return Color(.lightText)
            #endif
        case .sameAsSystem:
            return Color.secondary
        }
    }

    /// Tint applied to the Woo mini logo in the header. Uses `.accent` — WooCommercePurple
    /// shade 40 (light mode) / shade 30 (dark mode) — so it reads as a lighter, mode-adaptive
    /// brand purple instead of the heavy shade-60 `.brand` color. Falls back to a hardcoded
    /// shade-40 RGB on watchOS where the asset catalog isn't available.
    var logoTintColor: Color {
        switch self {
        case .brandPurple:
            return Color(.white)
        case .sameAsSystem:
            #if os(watchOS)
            // WooCommercePurple shade 40 (rgb 135, 62, 255).
            return Color(red: 0.529, green: 0.243, blue: 1.000)
            #else
            return Color(.accent)
            #endif
        }
    }

    /// Color for the dashed baseline rule in `MetricChartView` (visible only when the
    /// bar group clusters in the middle of a wide chart).
    var chartBaselineColor: Color {
        switch self {
        case .brandPurple: return Color.white.opacity(0.25)
        case .sameAsSystem: return Color.secondary.opacity(0.35)
        }
    }
}

// MARK: - Environment

private struct StoreWidgetThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: StoreWidgetTheme = .brandPurple
}

extension EnvironmentValues {
    var storeWidgetTheme: StoreWidgetTheme {
        get { self[StoreWidgetThemeEnvironmentKey.self] }
        set { self[StoreWidgetThemeEnvironmentKey.self] = newValue }
    }
}

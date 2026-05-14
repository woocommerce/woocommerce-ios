import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

/// User-selectable color scheme for the home-screen Store Stats widget. Exposed as an
/// AppIntent parameter via `StoreStatsConfigurationIntent.theme` and propagated to views
/// through the `\.storeWidgetTheme` SwiftUI environment.
///
/// The three "system" cases (`.light`, `.dark`, `.sameAsSystem`) share the same style
/// tokens — semantic system colors. The picker between them only changes which
/// `ColorScheme` the widget body renders against: forced light, forced dark, or whatever
/// the system is currently set to (see `forcedColorScheme`).
///
enum StoreWidgetTheme: String {
    /// Brand-purple background with white text and white logo.
    case brandPurple
    /// System widget appearance, forced to light mode regardless of the system setting.
    case light
    /// System widget appearance, forced to dark mode regardless of the system setting.
    case dark
    /// System widget appearance, following the current system light/dark setting.
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
            .light: DisplayRepresentation(title: "Light"),
            .dark: DisplayRepresentation(title: "Dark"),
            .sameAsSystem: DisplayRepresentation(title: "Same as system")
        ]
    }
}
#endif

// MARK: - Behavior

extension StoreWidgetTheme {
    /// Whether this theme renders against the system widget background (using semantic
    /// system colors) or the brand-purple background (using brand-tuned colors).
    var usesSystemAppearance: Bool {
        switch self {
        case .brandPurple: return false
        case .light, .dark, .sameAsSystem: return true
        }
    }

    /// Color scheme to force on the widget body, or `nil` to follow the system. Only
    /// the explicit `.light` and `.dark` themes pin a value; the others let SwiftUI
    /// resolve `\.colorScheme` from the system trait.
    var forcedColorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .brandPurple, .sameAsSystem: return nil
        }
    }
}

// MARK: - Style tokens

extension StoreWidgetTheme {
    /// Primary text color — store name, big metric values, body text.
    var primaryTextColor: Color {
        usesSystemAppearance ? Color.primary : Color(.white)
    }

    /// Secondary text color — date range, "As of …" line, metric titles.
    var secondaryTextColor: Color {
        if usesSystemAppearance {
            return Color.secondary
        }
        #if os(watchOS)
        return Color.white.opacity(0.7)
        #else
        return Color(.lightText)
        #endif
    }

    /// Tint applied to the Woo mini logo in the header. Uses `.accent` —
    /// WooCommercePurple shade 40 (light mode) / shade 30 (dark mode) — so the logo
    /// reads as a lighter, mode-adaptive brand purple instead of the heavy shade-60
    /// `.brand` color. Falls back to a hardcoded shade-40 RGB on watchOS where the
    /// asset catalog isn't available.
    var logoTintColor: Color {
        guard usesSystemAppearance else {
            return Color(.white)
        }
        #if os(watchOS)
        // WooCommercePurple shade 40 (rgb 135, 62, 255).
        return Color(red: 0.529, green: 0.243, blue: 1.000)
        #else
        return Color(.accent)
        #endif
    }

    /// Color for the dashed baseline rule in `MetricChartView` (visible only when the
    /// bar group clusters in the middle of a wide chart).
    var chartBaselineColor: Color {
        usesSystemAppearance ? Color.secondary.opacity(0.35) : Color.white.opacity(0.25)
    }
}

// MARK: - View helpers

extension View {
    /// Pins the widget body to a fixed `ColorScheme` when the theme demands it (`.light`
    /// or `.dark`). For themes that follow the system (`.sameAsSystem`, `.brandPurple`)
    /// this returns the view unchanged so SwiftUI keeps resolving `\.colorScheme` from
    /// the system trait.
    @ViewBuilder
    func storeWidgetForcedColorScheme(_ scheme: ColorScheme?) -> some View {
        if let scheme {
            environment(\.colorScheme, scheme)
        } else {
            self
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

import SwiftUI
import WidgetKit

private enum Layout {
    static let watchBrandColor = Color(red: 0.380, green: 0.031, blue: 0.808)

    static let backgroundBlueOpacity = 0.55
    static let backgroundPurpleOpacity = 0.35
    static let backgroundCyanOpacity = 0.25

    static let brandOverlayOpacity = 0.80

    static let highlightLeadingOpacity = 0.35
    static let highlightCenterOpacity = 0.05

    static let cornerRadius = 28.0
    static let borderOpacity = 0.28
    static let borderWidth = 1.0

    static var backgroundGradientColors: [Color] {
        [
            Color.blue.opacity(backgroundBlueOpacity),
            Color.purple.opacity(backgroundPurpleOpacity),
            Color.cyan.opacity(backgroundCyanOpacity)
        ]
    }

    static var highlightGradientColors: [Color] {
        [
            Color.white.opacity(highlightLeadingOpacity),
            Color.white.opacity(highlightCenterOpacity),
            Color.clear
        ]
    }
}

extension View {
    /// Adds backwards compatibility to the `containerBackground` API.
    /// This API is needed to add support to stand by mode widgets.
    ///
    func widgetBackground(backgroundView: some View) -> some View {
        if #available(watchOSApplicationExtension 10.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

enum StoreWidgetAppearance {
    private enum Keys {
        static let configurableStoreStatsWidgetsEnabled = "configurableStoreStatsWidgetsEnabled"
    }

    static var isModernAppearanceEnabled: Bool {
#if DEBUG
        return true
#endif
        UserDefaults(suiteName: WooConstants.sharedUserDefaultsSuiteName)?
            .bool(forKey: Keys.configurableStoreStatsWidgetsEnabled) ?? false
    }

    static var brandColor: Color {
#if os(watchOS)
        return Layout.watchBrandColor
#else
        return Color(UIColor.brand)
#endif
    }
}

struct StoreWidgetHomeScreenBackground: View {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode

    var body: some View {
        if StoreWidgetAppearance.isModernAppearanceEnabled {
            switch widgetRenderingMode {
            case .fullColor:
                ZStack {
                    LinearGradient(
                        colors: Layout.backgroundGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    StoreWidgetAppearance.brandColor.opacity(Layout.brandOverlayOpacity)
                    LinearGradient(
                        colors: Layout.highlightGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(Layout.borderOpacity), lineWidth: Layout.borderWidth)
                }
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius, style: .continuous))
            case .accented, .vibrant:
                Color.clear
            default:
                Color.clear
            }
        } else {
            StoreWidgetAppearance.brandColor
        }
    }
}

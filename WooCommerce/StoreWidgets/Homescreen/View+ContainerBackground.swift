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
    static var brandColor: Color {
#if os(watchOS)
        return Layout.watchBrandColor
#else
        return Color(.brand)
#endif
    }
}

struct StoreWidgetHomeScreenBackground: View {
    @Environment(\.widgetRenderingMode) private var widgetRenderingMode
    @Environment(\.storeWidgetTheme) private var theme

    var body: some View {
        switch widgetRenderingMode {
        case .fullColor:
            if theme.usesSystemAppearance {
                systemBackground
            } else {
                brandBackground
            }
        case .accented, .vibrant:
            Color.clear
        default:
            Color.clear
        }
    }

    @ViewBuilder
    private var systemBackground: some View {
        #if os(watchOS)
        // watchOS widgets don't have a `systemBackground` equivalent; fall back to brand.
        brandBackground
        #else
        Color(.systemBackground)
        #endif
    }

    @ViewBuilder
    private var brandBackground: some View {
#if os(watchOS)
        StoreWidgetAppearance.brandColor
#else
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
#endif
    }
}

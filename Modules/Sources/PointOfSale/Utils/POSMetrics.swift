import SwiftUI

struct POSMetrics: Equatable {
    struct Scale: Equatable {
        let none: CGFloat
        let xSmall: CGFloat
        let small: CGFloat
        let medium: CGFloat
        let large: CGFloat
        let xLarge: CGFloat
        let xxLarge: CGFloat
    }

    let spacing: Scale
    let padding: Scale
    let productCardSize: CGFloat
    let cartRowSize: CGFloat
    let checkboxSize: CGFloat

    var menuRowMinHeight: CGFloat {
        self == .compact ? 48 : 64
    }

    /// Illustration size on empty and error screens, matching Android POS (80pt, scaled to 75% on phones).
    var statusIllustrationSize: CGFloat {
        self == .compact ? 60 : 80
    }

    /// The onboarding guide only shows on iPhone, so its sizes depend on orientation rather than the layout scale.
    static func onboardingGuideIllustrationHeight(isVerticallyCompact: Bool) -> CGFloat {
        isVerticallyCompact ? 64 : 120
    }

    /// Before Dynamic Type scaling. As in the design, it keeps the guide's titles in line across steps.
    static let onboardingGuideTextMinHeight: CGFloat = 144

    var statusErrorMarkSize: POSErrorAndAlertIconSize {
        self == .compact ? .largeCompact : .large
    }

    static let regular = POSMetrics(spacing: .regular, padding: .regular, productCardSize: 112, cartRowSize: 96, checkboxSize: 32)
    static let compact = POSMetrics(spacing: .compact, padding: .compact, productCardSize: 96, cartRowSize: 80, checkboxSize: 24)

    static func metrics(for layoutScale: POSLayoutScale) -> POSMetrics {
        switch layoutScale {
        case .regular:
            .regular
        case .compact:
            .compact
        }
    }
}

extension POSMetrics.Scale {
    static let regular = POSMetrics.Scale(none: 0, xSmall: 4, small: 8, medium: 16, large: 24, xLarge: 32, xxLarge: 40)
    static let compact = POSMetrics.Scale(none: 0, xSmall: 4, small: 8, medium: 12, large: 16, xLarge: 20, xxLarge: 24)
}

extension EnvironmentValues {
    var posMetrics: POSMetrics {
        POSMetrics.metrics(for: posLayoutScale)
    }
}

private struct POSPaddingModifier: ViewModifier {
    @Environment(\.posMetrics) private var metrics

    let edges: Edge.Set
    let token: KeyPath<POSMetrics.Scale, CGFloat>

    func body(content: Content) -> some View {
        content.padding(edges, metrics.padding[keyPath: token])
    }
}

extension View {
    func posPadding(_ token: KeyPath<POSMetrics.Scale, CGFloat>) -> some View {
        posPadding(.all, token)
    }

    func posPadding(_ edges: Edge.Set, _ token: KeyPath<POSMetrics.Scale, CGFloat>) -> some View {
        modifier(POSPaddingModifier(edges: edges, token: token))
    }
}

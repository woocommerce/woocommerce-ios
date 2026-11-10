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

    static let regular = POSMetrics(spacing: .regular, padding: .regular, productCardSize: 112, cartRowSize: 96)
    static let compact = POSMetrics(spacing: .compact, padding: .compact, productCardSize: 96, cartRowSize: 80)

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
    func posPadding(_ edges: Edge.Set = .all, _ token: KeyPath<POSMetrics.Scale, CGFloat>) -> some View {
        modifier(POSPaddingModifier(edges: edges, token: token))
    }
}

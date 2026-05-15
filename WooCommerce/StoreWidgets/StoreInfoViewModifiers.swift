import Foundation
import SwiftUI

// MARK: StoreInfo widget view modifiers.
//
// Foreground colors switch on `\.storeWidgetTheme` from the environment so the same
// modifier renders correctly against either the brand-purple background (brandPurple) or
// the system widget background (sameAsSystem).

public struct StoreNameStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.footnote.weight(.bold))
            .foregroundColor(theme.primaryTextColor)
    }
}

public struct StatRangeStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(theme.secondaryTextColor)
    }
}

public struct StatTitleStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .foregroundColor(theme.secondaryTextColor)
    }
}

public struct StatValueStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundColor(theme.primaryTextColor)
    }
}

public struct StatTitleLargeStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.subheadline.bold())
            .foregroundColor(theme.secondaryTextColor)
    }
}

public struct StatValueLargeStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(theme.primaryTextColor)
    }
}

public struct StatTrendIndicatorStyle: ViewModifier {
    @ScaledMetric(relativeTo: .caption2) private var fontSize = 7.0

    public func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
    }
}

public struct StatTrendIndicatorLargeStyle: ViewModifier {
    @ScaledMetric(relativeTo: .footnote) private var fontSize = 11.0

    public func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
    }
}

public struct StatTrendTextStyle: ViewModifier {
    @ScaledMetric(relativeTo: .caption2) private var fontSize = 9.0

    public func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
    }
}

public struct StatTrendTextLargeStyle: ViewModifier {
    @ScaledMetric(relativeTo: .footnote) private var fontSize = 13.0

    public func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .bold))
    }
}

public struct StatTextStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(theme.primaryTextColor)
    }
}

public struct StatButtonStyle: ViewModifier {
    @Environment(\.storeWidgetTheme) private var theme

    public func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundColor(theme.primaryTextColor)
    }
}

// MARK: View Extensions.
extension View {
    func storeNameStyle() -> some View {
        self.modifier(StoreNameStyle())
    }

    func statRangeStyle() -> some View {
        self.modifier(StatRangeStyle())
    }

    func statTitleStyle() -> some View {
        self.modifier(StatTitleStyle())
    }

    func statValueStyle() -> some View {
        self.modifier(StatValueStyle())
    }

    func statTitleLargeStyle() -> some View {
        self.modifier(StatTitleLargeStyle())
    }

    func statValueLargeStyle() -> some View {
        self.modifier(StatValueLargeStyle())
    }

    func statTrendIndicatorStyle() -> some View {
        self.modifier(StatTrendIndicatorStyle())
    }

    func statTrendIndicatorLargeStyle() -> some View {
        self.modifier(StatTrendIndicatorLargeStyle())
    }

    func statTrendTextStyle() -> some View {
        self.modifier(StatTrendTextStyle())
    }

    func statTrendTextLargeStyle() -> some View {
        self.modifier(StatTrendTextLargeStyle())
    }

    func statTextStyle() -> some View {
        self.modifier(StatTextStyle())
    }

    func statButtonStyle() -> some View {
        self.modifier(StatButtonStyle())
    }
}

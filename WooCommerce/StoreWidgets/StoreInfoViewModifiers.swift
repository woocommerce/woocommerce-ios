import Foundation
import SwiftUI

// MARK: StoreInfo widget view modifiers.

public struct StoreNameStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.footnote.weight(.bold))
            .foregroundColor(Color(.white))
    }
}

public struct StatRangeStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(Color(.lightText))
    }
}

public struct StatTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.caption.bold())
            .foregroundColor(Color(.lightText))
    }
}

public struct StatValueStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.title3)
            .foregroundColor(Color(.white))
    }
}

public struct StatTitleLargeStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.subheadline.bold())
            .foregroundColor(Color(.lightText))
    }
}

public struct StatValueLargeStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.title2)
            .foregroundColor(Color(.white))
    }
}

public struct StatTrendIndicatorStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 7, weight: .bold))
    }
}

public struct StatTrendIndicatorLargeStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 11, weight: .bold))
    }
}

public struct StatTrendTextStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 9, weight: .bold))
    }
}

public struct StatTrendTextLargeStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .bold))
    }
}

public struct StatTextStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(Color(.white))
    }
}

public struct StatButtonStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color(.white))
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

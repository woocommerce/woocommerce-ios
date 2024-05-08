#if os(iOS)

import Foundation
import SwiftUI

/// Woo style modifiers.
/// Migrate them from `UILabel+Helpers` or  `UIButton+helpers` as needed.
///

// MARK: Woo Styles
public struct BodyStyle: ViewModifier {
    /// Whether the View being modified is enabled
    ///
    var isEnabled: Bool

    /// View opacity
    ///
    var opacity: Double

    public init(isEnabled: Bool, opacity: Double) {
        self.isEnabled = isEnabled
        self.opacity = opacity
    }

    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(isEnabled ? Color(.text) : Color(.textTertiary))
            .opacity(opacity)
    }
}


public struct LargeTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.largeTitle)
            .foregroundColor(Color(.text))
    }
}

public struct TitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.title)
            .foregroundColor(Color(.text))
    }
}

public struct SecondaryTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.title2.weight(.bold))
            .foregroundColor(Color(.text))
    }
}

public struct TertiaryTitleStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.title3.weight(.bold))
            .foregroundColor(Color(.text))
    }
}

public struct SecondaryBodyStyle: ViewModifier {

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.textSubtle))
    }
}

public struct HeadlineStyle: ViewModifier {

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color(.text))
    }
}

struct SubheadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.subheadline)
            .foregroundColor(Color(.textSubtle))
    }
}

public struct FootnoteStyle: ViewModifier {
    /// Whether the View being modified is enabled
    ///
    var isEnabled: Bool

    /// Whether the View shows error state
    ///
    var isError: Bool

    public func body(content: Content) -> some View {
        content
            .font(.footnote)
            .foregroundColor(textColor)
    }

    private var textColor: Color {
        switch (isEnabled, isError) {
        case (true, false):
            return Color(.textSubtle)
        case (_, true):
            return Color(.error)
        case (false, _):
            return Color(.textTertiary)
        }
    }
}

public struct CalloutStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.callout)
            .foregroundColor(Color(.textSubtle))
    }
}

public struct CaptionStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(Color(.text))
    }
}

public struct ErrorStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.error))
    }
}

// The color of the bar button items in the navigation bar
//
public struct WooNavigationBarStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .tint(Color(.accent))
    }
}

public struct LinkStyle: ViewModifier {
    /// Environment `enabled` state.
    ///
    @Environment(\.isEnabled) var isEnabled

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(isEnabled ? Color(.accent) : Color(.textTertiary))
    }
}

public struct IconStyle: ViewModifier {
    /// Environment `enabled` state.
    ///
    @Environment(\.isEnabled) var isEnabled

    public init() {}

    public func body(content: Content) -> some View {
        content
            .foregroundColor(isEnabled ? Color(.accent) : Color(.textTertiary))
    }
}

public struct HeadlineLinkStyle: ViewModifier {
    /// Environment `enabled` state.
    ///
    @Environment(\.isEnabled) var isEnabled

    public init() {}

    public func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(isEnabled ? Color(.accent) : Color(.textTertiary))
    }
}

// MARK: View extensions
public extension View {
    /// - Parameters:
    ///     - isEnabled: Whether the view is enabled (to apply specific styles for disabled view)
    func bodyStyle(_ isEnabled: Bool = true, opacity: Double = 1.0) -> some View {
        self.modifier(BodyStyle(isEnabled: isEnabled, opacity: opacity))
    }

    func secondaryBodyStyle() -> some View {
        self.modifier(SecondaryBodyStyle())
    }

    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }

    func subheadlineStyle() -> some View {
        self.modifier(SubheadlineStyle())
    }

    func largeTitleStyle() -> some View {
        self.modifier(LargeTitleStyle())
    }

    func titleStyle() -> some View {
        self.modifier(TitleStyle())
    }

    func secondaryTitleStyle() -> some View {
        self.modifier(SecondaryTitleStyle())
    }

    func tertiaryTitleStyle() -> some View {
        self.modifier(TertiaryTitleStyle())
    }

    /// - Parameters:
    ///     - isEnabled: Whether the view is enabled (to apply specific styles for disabled view)
    ///     - isError: Whether the view shows error state.
    func footnoteStyle(isEnabled: Bool = true, isError: Bool = false) -> some View {
        self.modifier(FootnoteStyle(isEnabled: isEnabled, isError: isError))
    }

    func errorStyle() -> some View {
        self.modifier(ErrorStyle())
    }

    func wooNavigationBarStyle() -> some View {
        self.modifier(WooNavigationBarStyle())
    }

    func linkStyle() -> some View {
        self.modifier(LinkStyle())
    }

    func headlineLinkStyle() -> some View {
        self.modifier(HeadlineLinkStyle())
    }

    func calloutStyle() -> some View {
        self.modifier(CalloutStyle())
    }

    func captionStyle() -> some View {
        self.modifier(CaptionStyle())
    }

    func iconStyle(_ isEnabled: Bool = true) -> some View {
        self.modifier(IconStyle())
    }
}

#endif

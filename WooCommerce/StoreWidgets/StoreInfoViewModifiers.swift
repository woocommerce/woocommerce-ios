import Foundation
import SwiftUI

// MARK: StoreInfo widget view modifiers.

public struct StoreNameStyle: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .font(.footnote.weight(.bold))
            .foregroundColor(Color(.textInverted))
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
            .font(.title2)
            .foregroundColor(Color(.textInverted))
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
}

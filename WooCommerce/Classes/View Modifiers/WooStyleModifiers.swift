import Foundation
import SwiftUI

/// Woo style modifiers.
/// Migrate them from `UILabel+Helpers` or  `UIButton+helpers` as needed.
///

// MARK: Body Style
struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.text))
    }
}

extension View {
    func bodyStyle() -> some View {
        self.modifier(BodyStyle())
    }
}


// MARK: Secondary Body Style
struct SecondaryBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.textSubtle))
    }
}

extension View {
    func secondaryBodyStyle() -> some View {
        self.modifier(SecondaryBodyStyle())
    }
}


// MARK: Headline Style
struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color(.text))
    }
}

extension View {
    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }
}

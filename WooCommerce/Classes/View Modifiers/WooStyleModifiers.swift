import Foundation
import SwiftUI

/// Woo style modifiers.
/// Migrate them from `UILabel+Helpers` or  `UIButton+helpers` as needed.
///

// MARK: Woo Styles
struct BodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.text))
    }
}

struct SecondaryBodyStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(Color(.textSubtle))
    }
}

struct HeadlineStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color(.text))
    }
}

// MARK: View extensions
extension View {
    func bodyStyle() -> some View {
        self.modifier(BodyStyle())
    }

    func secondaryBodyStyle() -> some View {
        self.modifier(SecondaryBodyStyle())
    }

    func headlineStyle() -> some View {
        self.modifier(HeadlineStyle())
    }
}

import Foundation
import SwiftUI

/// Defines shadow styles used across POS UI components.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-22_7198
enum POSShadowStyle {
    case medium
    case large
}

/// A ViewModifier that applies predefined shadow styles.
struct POSShadowStyleModifier: ViewModifier {
    let style: POSShadowStyle

    func body(content: Content) -> some View {
        switch style {
        case .medium:
            content
                .shadow(color: Color.posShadow.opacity(0.02), radius: 16, x: 0, y: 16)
                .shadow(color: Color.posShadow.opacity(0.03), radius: 8, x: 0, y: 4)
                .shadow(color: Color.posShadow.opacity(0.04), radius: 5, x: 0, y: 4)
                .shadow(color: Color.posShadow.opacity(0.05), radius: 3, x: 0, y: 2)
        case .large:
            content
                .shadow(color: Color.posShadow.opacity(0.02), radius: 43, x: 0, y: 50)
                .shadow(color: Color.posShadow.opacity(0.04), radius: 36, x: 0, y: 30)
                .shadow(color: Color.posShadow.opacity(0.07), radius: 27, x: 0, y: 15)
                .shadow(color: Color.posShadow.opacity(0.08), radius: 15, x: 0, y: 5)
        }
    }
}

extension View {
    /// Applies a shadow style to the view.
    /// - Parameter style: The shadow style to apply.
    func posShadow(_ style: POSShadowStyle) -> some View {
        modifier(POSShadowStyleModifier(style: style))
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Medium Shadow")
            .padding()
            .frame(width: 200, height: 100)
            .foregroundStyle(Color.posOnSecondaryContainer)
            .background(Color.posOutlineVariant)
            .posShadow(.medium)

        Text("Large Shadow")
            .padding()
            .frame(width: 200, height: 100)
            .foregroundStyle(Color.posOnSecondaryContainer)
            .background(Color.posOutlineVariant)
            .posShadow(.large)
    }
    .padding(100)
}

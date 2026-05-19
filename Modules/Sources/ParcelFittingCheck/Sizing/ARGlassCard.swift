import SwiftUI

struct ARGlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    private static var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: ARGlassCardConstants.cornerRadius)
    }

    var body: some View {
        content()
            .padding(ARGlassCardConstants.padding)
            .background(ARGlassCardConstants.backgroundColor, in: Self.shape)
            .overlay(Self.shape.stroke(ARGlassCardConstants.borderColor, lineWidth: 1))
            .shadow(color: ARGlassCardConstants.shadowColor, radius: 30, y: 12)
    }
}

private enum ARGlassCardConstants {
    static let cornerRadius: CGFloat = 18
    static let padding: CGFloat = 14
    static let backgroundColor = Color(red: 28 / 255, green: 28 / 255, blue: 30 / 255).opacity(0.85)
    static let borderColor = Color.white.opacity(0.09)
    static let shadowColor = Color.black.opacity(0.35)
}

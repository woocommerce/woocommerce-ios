import SwiftUI

public struct StoreDivider: View {
    // Draw the line at one physical pixel (1 / displayScale) so it stays crisp and uniform;
    // a fixed 0.5pt is 1.5px on @3x and rasterizes unevenly between adjacent dividers.
    @Environment(\.displayScale) private var displayScale

    private let variant: StoreDividerVariant

    public init(variant: StoreDividerVariant = .full) {
        self.variant = variant
    }

    public var body: some View {
        Rectangle()
            .fill(Color.storeStateLayerOnSurfaceOpacity16)
            .frame(height: 1 / displayScale)
            .padding(.horizontal, variant.horizontalInset)
            .accessibilityHidden(true)
    }
}

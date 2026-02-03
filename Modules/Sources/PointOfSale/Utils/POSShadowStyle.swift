import Foundation
import SwiftUI
import UIKit

/// Defines shadow styles used across POS UI components.
/// Design ref: 1qcjzXitBHU7xPnpCOWnNM-fi-22_7198
enum POSShadowStyle {
    case none
    case medium
    case large
}

// MARK: - Shadow Layer Definition

private struct POSShadowLayer {
    let color: UIColor
    let opacity: Float
    let radius: CGFloat
    let offset: CGSize
}

// MARK: - Main SwiftUI Modifier

struct POSShadowStyleModifier: ViewModifier {
    let style: POSShadowStyle
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    let shadowLayers = shadowLayers(for: style)
                    RasterizedShadowBackground(
                        cornerRadius: cornerRadius,
                        shadowLayers: shadowLayers
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            )
    }

    private func shadowLayers(for style: POSShadowStyle) -> [POSShadowLayer] {
        switch style {
        case .none:
            return []
        case .medium:
            return [
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.02, radius: 16, offset: CGSize(width: 0, height: 16)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.03, radius: 8, offset: CGSize(width: 0, height: 4)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.04, radius: 5, offset: CGSize(width: 0, height: 4)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.05, radius: 3, offset: CGSize(width: 0, height: 2))
            ]
        case .large:
            return [
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.02, radius: 43, offset: CGSize(width: 0, height: 50)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.04, radius: 36, offset: CGSize(width: 0, height: 30)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.07, radius: 27, offset: CGSize(width: 0, height: 15)),
                POSShadowLayer(color: UIColor(Color.posShadow), opacity: 0.08, radius: 15, offset: CGSize(width: 0, height: 5))
            ]
        }
    }
}

extension View {
    /// Applies a shadow style to the view.
    /// - Parameters:
    ///   - style: The shadow style to apply.
    ///   - cornerRadius: The corner radius for the shadow background. Default is 0.
    func posShadow(_ style: POSShadowStyle, cornerRadius: CGFloat = 0) -> some View {
        modifier(POSShadowStyleModifier(style: style, cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 40) {
        Text("Medium Shadow")
            .padding()
            .frame(width: 200, height: 100)
            .foregroundStyle(Color.posOnSecondaryContainer)
            .background(Color.posOutlineVariant)
            .posShadow(.medium, cornerRadius: 12)

        Text("Large Shadow")
            .padding()
            .frame(width: 200, height: 100)
            .foregroundStyle(Color.posOnSecondaryContainer)
            .background(Color.posOutlineVariant)
            .posShadow(.large, cornerRadius: 16)
    }
    .padding(100)
}

// MARK: - UIKit Implementation (Private)

/**
 UIKit Implementation for POS Shadows
 -----------------------------------

 Instead of stacking multiple SwiftUI `.shadow` modifiers (which each require separate blur calculations
 and compositing operations, which can be costly in lists or scrolling views), this approach uses a
 custom `UIView` (`MultiShadowView`) that composes multiple `CALayer` sublayers, each with its own shadow configuration.

 Performance Benefits:
 - All shadow operations are rasterized and composited using multiple `CALayer`s within a single view hierarchy.
 - Avoids SwiftUI’s per-shadow blur and composition cost, which can accumulate in scroll views or complex layouts.
 - `CALayer` shadows are GPU-accelerated and benefit from `shouldRasterize`, enabling efficient reuse of cached shadow bitmaps.
 - Explicit `shadowPath` avoids expensive runtime shape calculations and improves rendering performance.
*/

private class MultiShadowView: UIView {
    var cornerRadius: CGFloat = 0
    var shadowLayers: [POSShadowLayer] = []

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.removeAll(where: { $0.name == "posShadowLayer" })
        for (index, shadow) in shadowLayers.enumerated() {
            let shadowLayer = CALayer()
            shadowLayer.name = "posShadowLayer"
            shadowLayer.frame = bounds
            shadowLayer.backgroundColor = UIColor.clear.cgColor
            shadowLayer.cornerRadius = cornerRadius
            shadowLayer.shadowColor = shadow.color.cgColor
            shadowLayer.shadowOpacity = shadow.opacity
            shadowLayer.shadowRadius = shadow.radius
            shadowLayer.shadowOffset = shadow.offset
            shadowLayer.masksToBounds = false
            shadowLayer.shouldRasterize = true
            shadowLayer.rasterizationScale = UIScreen.main.scale
            shadowLayer.shadowPath = UIBezierPath(roundedRect: shadowLayer.bounds, cornerRadius: cornerRadius).cgPath
            layer.insertSublayer(shadowLayer, at: UInt32(index))
        }
    }
}

private struct RasterizedShadowBackground: UIViewRepresentable {
    let cornerRadius: CGFloat
    let shadowLayers: [POSShadowLayer]

    func makeUIView(context: Context) -> MultiShadowView {
        let view = MultiShadowView()
        view.cornerRadius = cornerRadius
        view.shadowLayers = shadowLayers
        return view
    }

    func updateUIView(_ uiView: MultiShadowView, context: Context) {
        uiView.cornerRadius = cornerRadius
        uiView.shadowLayers = shadowLayers
        uiView.setNeedsLayout()
    }
}

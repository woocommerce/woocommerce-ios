import SwiftUI
import UIKit
import Shimmer

/// Native redacted text placeholder that follows a POS text style and Dynamic Type.
/// Redaction draws a bar as tall as the font's cap height, so the sample is drawn larger than `font`:
/// the bar is about as tall as the style's point size, while the line keeps the style's height.
struct POSPlaceholderText: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.posLayoutScale) private var layoutScale

    private let text: String
    private let font: POSFontStyle

    init(_ text: String, font: POSFontStyle) {
        self.text = text
        self.font = font
    }

    var body: some View {
        let size = font.effectiveFontSize(for: layoutScale, contentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        ZStack(alignment: .leading) {
            // Takes the loaded text's line height, so the layout matches the loaded content.
            Text(verbatim: text)
                .font(font)
                .lineLimit(1)
                .hidden()
            // Zero layout height keeps the larger sample centered on the loaded line.
            Text(verbatim: text)
                .font(.system(size: size / POSPlaceholderMetrics.capHeightRatio))
                .foregroundStyle(Color.posOnSurface)
                .lineLimit(1)
                .posLoadingPlaceholder()
                .frame(height: 0)
        }
        .accessibilityHidden(true)
    }
}

/// Native redacted loading bar with an exact size.
/// A long sample line is clipped to the bar frame, so the redacted bar spans exactly `width`.
/// Redaction draws a bar as tall as the font's cap height, so the font is sized from `height`.
struct POSPlaceholderBar: View {
    /// When nil, the bar stretches to the available width.
    let width: CGFloat?
    let height: CGFloat
    var cornerRadius: CGFloat = POSCornerRadiusStyle.small.value

    var body: some View {
        // The sample line is an overlay, so its natural width never affects layout.
        Color.clear
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil)
            .overlay(alignment: .leading) {
                Text(verbatim: .redactedPlaceholder(length: Constants.sampleLength))
                    .font(.system(size: height / POSPlaceholderMetrics.capHeightRatio))
                    .foregroundStyle(Color.posOnSurface)
                    .lineLimit(1)
                    .fixedSize()
                    // Shimmer only the fixed-size sample. Its mask then keeps one size,
                    // even when a full-width bar settles its width after appearing.
                    .posLoadingPlaceholder()
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityHidden(true)
    }
}

private extension POSPlaceholderBar {
    enum Constants {
        // Wide enough to fill a full-width phone bar; the shimmer band moves across this sample.
        static let sampleLength = 14
    }
}

enum POSPlaceholderMetrics {
    static let capHeightRatio = UIFont.systemFont(ofSize: 100).capHeight / 100
}

enum POSLoadingPlaceholderStyle {
    // With the gradient's 0.86 resting mask, image placeholders keep the previous 0.3 resting opacity.
    static let imageBaseOpacity = 0.35

    // Matches the previous resting color. Redaction cannot reach the old dark band, so a lighter band moves instead.
    static var shimmerGradient: Gradient { Gradient(colors: [.black.opacity(0.86), .black.opacity(0.3), .black.opacity(0.86)]) }
}

extension String {
    /// Representative content for native text placeholders. Redaction and shimmer are applied by the view.
    static func redactedPlaceholder(length: Int) -> String {
        String(repeating: "X", count: Swift.max(0, length))
    }
}

extension View {
    func posLoadingPlaceholder() -> some View {
        redacted(reason: .placeholder)
            .shimmering(gradient: POSLoadingPlaceholderStyle.shimmerGradient)
            .geometryGroup()
    }
}

#Preview {
    VStack(alignment: .leading, spacing: POSSpacing.medium) {
        POSPlaceholderText(.redactedPlaceholder(length: 8), font: .posBodySmallRegular())
        POSPlaceholderText(.redactedPlaceholder(length: 8), font: .posBodyLargeBold)
        POSPlaceholderBar(width: 120, height: 16)
        POSPlaceholderBar(width: 80, height: 24)
        POSPlaceholderBar(width: nil, height: 32, cornerRadius: POSCornerRadiusStyle.medium.value)
    }
    .padding(POSPadding.medium)
}

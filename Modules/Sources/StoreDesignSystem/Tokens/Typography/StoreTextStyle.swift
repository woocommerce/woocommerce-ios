import SwiftUI

public struct StoreTextStyle: Equatable {
    public let size: CGFloat
    public let lineHeight: CGFloat
    public let tracking: CGFloat
    public let weight: Font.Weight

    private init(size: CGFloat, lineHeight: CGFloat, tracking: CGFloat, weight: Font.Weight) {
        self.size = size
        self.lineHeight = lineHeight
        self.tracking = tracking
        self.weight = weight
    }
}

// MARK: - Presets (Regular weight; use .emphasized / .strong for heavier weights)
public extension StoreTextStyle {
    static let displayLarge = StoreTextStyle(size: 56, lineHeight: 64, tracking: -2.5, weight: .regular)
    static let displayMedium = StoreTextStyle(size: 48, lineHeight: 52, tracking: -2.5, weight: .regular)
    static let displaySmall = StoreTextStyle(size: 36, lineHeight: 44, tracking: -2.5, weight: .regular)

    static let headlineLarge = StoreTextStyle(size: 34, lineHeight: 40, tracking: -1.5, weight: .regular)
    static let headlineMedium = StoreTextStyle(size: 28, lineHeight: 36, tracking: -1, weight: .regular)
    static let headlineSmall = StoreTextStyle(size: 24, lineHeight: 32, tracking: -0.75, weight: .regular)

    static let titleLarge = StoreTextStyle(size: 20, lineHeight: 28, tracking: -0.41, weight: .regular)
    static let titleMedium = StoreTextStyle(size: 17, lineHeight: 20, tracking: -0.41, weight: .regular)
    static let titleSmall = StoreTextStyle(size: 14, lineHeight: 16, tracking: -0.41, weight: .regular)

    static let labelLarge = StoreTextStyle(size: 17, lineHeight: 24, tracking: -0.41, weight: .regular)
    static let labelMedium = StoreTextStyle(size: 14, lineHeight: 20, tracking: -0.41, weight: .regular)
    static let labelSmall = StoreTextStyle(size: 10, lineHeight: 14, tracking: -0.07, weight: .regular)

    static let bodyLarge = StoreTextStyle(size: 17, lineHeight: 24, tracking: -0.41, weight: .regular)
    static let bodyMedium = StoreTextStyle(size: 14, lineHeight: 20, tracking: -0.41, weight: .regular)
    static let bodySmall = StoreTextStyle(size: 12, lineHeight: 16, tracking: 0, weight: .regular)
}

// MARK: - Emphasis derivations (weight axis only — size/line-height/tracking unchanged)
public extension StoreTextStyle {
    /// Emphasized weight (Medium).
    var emphasized: StoreTextStyle { weighted(.medium) }
    /// Strong weight (Bold).
    var strong: StoreTextStyle { weighted(.bold) }

    private func weighted(_ weight: Font.Weight) -> StoreTextStyle {
        StoreTextStyle(size: size, lineHeight: lineHeight, tracking: tracking, weight: weight)
    }
}

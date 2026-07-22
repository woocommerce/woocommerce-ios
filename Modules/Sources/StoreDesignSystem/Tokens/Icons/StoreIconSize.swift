import CoreGraphics

/// Unlike the other scalar ramps (StoreSpacing, StorePadding, StoreRadius,
/// StoreStrokeWidth), which stay plain CGFloat constants because they feed Apple's
/// CGFloat parameters, icon size is a closed type: its only consumer is our own
/// `StoreIconImage.image(size:)`, so typing it blocks arbitrary sizes and enables
/// dot-shorthand (`.image(size: .medium)`).
public struct StoreIconSize {
    let value: CGFloat

    private init(_ value: CGFloat) {
        self.value = value
    }

    /// Extra small — 14 pt
    public static let extraSmall = StoreIconSize(14)
    /// Small — 16 pt
    public static let small = StoreIconSize(16)
    /// Medium — 18 pt
    public static let medium = StoreIconSize(18)
    /// Large — 20 pt
    public static let large = StoreIconSize(20)
    /// Large Increased — 24 pt
    public static let largeIncreased = StoreIconSize(24)
    /// Extra Large — 32 pt
    public static let extraLarge = StoreIconSize(32)
}

import CoreGraphics

public enum StoreSize {
    /// Minimum interactive (touch-target) size — the Apple HIG minimum. A platform accessibility
    /// constant rather than a Figma design value, centralized so every interactive component shares it.
    public static let minimumTapTarget: CGFloat = 44
}

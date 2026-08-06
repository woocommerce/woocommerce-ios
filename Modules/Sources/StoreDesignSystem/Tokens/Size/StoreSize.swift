import CoreGraphics

public enum StoreSize {
    /// Minimum interactive (touch-target) size — the Apple HIG minimum. A platform accessibility
    /// constant rather than a Figma design value, centralized so every interactive component shares it.
    public static let minimumTapTarget: CGFloat = 44

    /// Heights for compact controls whose design defines height via vertical padding around
    /// cap-height-trimmed text. SwiftUI's `Text` isn't cap-trimmed, so components pin these as a
    /// `minHeight` floor instead of literal vertical padding, which would overshoot. Centralized so a
    /// new component reuses the pattern rather than reintroducing its own literal.
    public static let badgeHeight: CGFloat = 24
    public static let segmentedControlHeight: CGFloat = 32

    /// The fixed decorative container size of a `StoreIconContainer`. Equal in value to
    /// `minimumTapTarget` but a distinct design dimension: the component is non-interactive,
    /// so this is not a touch-target constant.
    public static let iconContainerSize: CGFloat = 44
}

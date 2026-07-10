import CoreGraphics

public enum StoreRadius {
    /// Corner Radius/None — 0 pt
    public static let none: CGFloat = 0
    /// Corner Radius/Extra-Small — 2 pt
    public static let extraSmall: CGFloat = 2
    /// Corner Radius/Small — 4 pt
    public static let small: CGFloat = 4
    /// Corner Radius/Medium — 8 pt
    public static let medium: CGFloat = 8
    /// Corner Radius/Large — 12 pt
    public static let large: CGFloat = 12
    /// Corner Radius/Extra Large — 16 pt
    public static let extraLarge: CGFloat = 16
    /// Corner Radius/Full — 999 pt (fully rounded / pill)
    public static let full: CGFloat = 999
}

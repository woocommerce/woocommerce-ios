//  StoreRadius.swift
//
//  Corner radius scale from the Mobile Design System Figma ("Corner Radius/Name").
//  Use for `.cornerRadius(...)` / `RoundedRectangle(cornerRadius:)`. Named (t-shirt)
//  steps, mirroring the design's own naming.

import CoreGraphics

/// The design system's corner radius ramp. Closed for construction: reference a named
/// step (`StoreRadius.medium`), never an arbitrary value. `full` is a pill sentinel —
/// a value large enough to fully round any reasonably sized element into a capsule.
public enum StoreRadius {
    /// Figma Corner Radius/None — 0 pt
    public static let none: CGFloat = 0
    /// Figma Corner Radius/Extra-Small — 2 pt
    public static let extraSmall: CGFloat = 2
    /// Figma Corner Radius/Small — 4 pt
    public static let small: CGFloat = 4
    /// Figma Corner Radius/Medium — 8 pt
    public static let medium: CGFloat = 8
    /// Figma Corner Radius/Large — 12 pt
    public static let large: CGFloat = 12
    /// Figma Corner Radius/Extra Large — 16 pt
    public static let extraLarge: CGFloat = 16
    /// Figma Corner Radius/Full — 999 pt (fully rounded / pill)
    public static let full: CGFloat = 999
}

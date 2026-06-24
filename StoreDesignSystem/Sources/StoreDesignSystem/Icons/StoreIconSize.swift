//  StoreIconSize.swift
//
//  Icon size scale from the Mobile Design System Figma ("Icon" → Size).
//  The dimension (width == height) for design-system icons.

import CoreGraphics

/// The design system's icon size ramp. Closed for construction: reference a named step
/// (`StoreIconSize.medium`), never an arbitrary value.
public enum StoreIconSize {
    /// Figma Icon/Size/Extra small — 14 pt
    public static let extraSmall: CGFloat = 14
    /// Figma Icon/Size/Small — 16 pt
    public static let small: CGFloat = 16
    /// Figma Icon/Size/Medium — 18 pt
    public static let medium: CGFloat = 18
    /// Figma Icon/Size/Large — 20 pt
    public static let large: CGFloat = 20
    /// Figma Icon/Size/Large Increased — 24 pt
    public static let largeIncreased: CGFloat = 24
    /// Figma Icon/Size/Extra Large — 32 pt
    public static let extraLarge: CGFloat = 32
}

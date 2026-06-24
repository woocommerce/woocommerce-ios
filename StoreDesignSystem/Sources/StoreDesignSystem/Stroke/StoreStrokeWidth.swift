//  StoreStrokeWidth.swift
//
//  Stroke / border width scale from the Mobile Design System Figma
//  ("Shape" → Stroke/Weight). Use for border and stroke line widths.

import CoreGraphics

/// The design system's stroke (border) width ramp. Closed for construction: reference a
/// named step (`StoreStrokeWidth.regular`), never an arbitrary value.
public enum StoreStrokeWidth {
    /// Figma Stroke/Weight/None — 0 pt
    public static let none: CGFloat = 0
    /// Figma Stroke/Weight/Extra-Thin — 0.5 pt
    public static let extraThin: CGFloat = 0.5
    /// Figma Stroke/Weight/Thin — 0.75 pt
    public static let thin: CGFloat = 0.75
    /// Figma Stroke/Weight/Regular — 1 pt
    public static let regular: CGFloat = 1
    /// Figma Stroke/Weight/Medium — 1.5 pt
    public static let medium: CGFloat = 1.5
    /// Figma Stroke/Weight/Medium Increased — 2 pt
    public static let mediumIncreased: CGFloat = 2
    /// Figma Stroke/Weight/Thick — 3 pt
    public static let thick: CGFloat = 3
    /// Figma Stroke/Weight/Extra Thick — 4 pt
    public static let extraThick: CGFloat = 4
}

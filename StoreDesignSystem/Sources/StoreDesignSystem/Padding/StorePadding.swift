//  StorePadding.swift
//
//  Padding scale from the Mobile Design System Figma ("Padding/N", 0...12).
//  Use for padding inside containers (e.g. `.padding(...)`). A separate scale from
//  spacing on purpose: the two express different intent and may diverge over time,
//  so this enum carries its own values rather than aliasing StoreSpacing.

import CoreGraphics

/// The design system's padding ramp. Closed for construction: reference a named
/// step (`StorePadding.p4`), never an arbitrary value.
public enum StorePadding {
    /// Figma Padding/0 — 0 pt
    public static let p0: CGFloat = 0
    /// Figma Padding/1 — 2 pt
    public static let p1: CGFloat = 2
    /// Figma Padding/2 — 4 pt
    public static let p2: CGFloat = 4
    /// Figma Padding/3 — 8 pt
    public static let p3: CGFloat = 8
    /// Figma Padding/4 — 12 pt
    public static let p4: CGFloat = 12
    /// Figma Padding/5 — 16 pt
    public static let p5: CGFloat = 16
    /// Figma Padding/6 — 20 pt
    public static let p6: CGFloat = 20
    /// Figma Padding/7 — 24 pt
    public static let p7: CGFloat = 24
    /// Figma Padding/8 — 32 pt
    public static let p8: CGFloat = 32
    /// Figma Padding/9 — 40 pt
    public static let p9: CGFloat = 40
    /// Figma Padding/10 — 48 pt
    public static let p10: CGFloat = 48
    /// Figma Padding/11 — 56 pt
    public static let p11: CGFloat = 56
    /// Figma Padding/12 — 64 pt
    public static let p12: CGFloat = 64
}

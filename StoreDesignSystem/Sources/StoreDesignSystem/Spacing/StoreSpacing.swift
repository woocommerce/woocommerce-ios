//  StoreSpacing.swift
//
//  Spacing scale from the Mobile Design System Figma ("Spacing/N", 0...12).
//  Use for gaps between elements (e.g. HStack/VStack `spacing:`). Kept distinct
//  from padding — they are separate scales in the design system.

import CoreGraphics

/// The design system's spacing ramp. Closed for construction: reference a named
/// step (`StoreSpacing.s4`), never an arbitrary value.
public enum StoreSpacing {
    /// Figma Spacing/0 — 0 pt
    public static let s0: CGFloat = 0
    /// Figma Spacing/1 — 2 pt
    public static let s1: CGFloat = 2
    /// Figma Spacing/2 — 4 pt
    public static let s2: CGFloat = 4
    /// Figma Spacing/3 — 8 pt
    public static let s3: CGFloat = 8
    /// Figma Spacing/4 — 12 pt
    public static let s4: CGFloat = 12
    /// Figma Spacing/5 — 16 pt
    public static let s5: CGFloat = 16
    /// Figma Spacing/6 — 20 pt
    public static let s6: CGFloat = 20
    /// Figma Spacing/7 — 24 pt
    public static let s7: CGFloat = 24
    /// Figma Spacing/8 — 32 pt
    public static let s8: CGFloat = 32
    /// Figma Spacing/9 — 40 pt
    public static let s9: CGFloat = 40
    /// Figma Spacing/10 — 48 pt
    public static let s10: CGFloat = 48
    /// Figma Spacing/11 — 56 pt
    public static let s11: CGFloat = 56
    /// Figma Spacing/12 — 64 pt
    public static let s12: CGFloat = 64
}

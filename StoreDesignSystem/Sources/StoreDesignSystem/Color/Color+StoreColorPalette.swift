//  Color+StoreColorPalette.swift
//
//  Color roles from the Figma variables export (Mobile Design System, "Woo theme").
//  Light + Dark only; high contrast is intentionally not modeled yet. NOTE: the Dark
//  values are provisional — design is still revising them; re-sync from a fresh
//  export when the revision lands.

import SwiftUI

/// The design system's color roles. Declared on `ShapeStyle where Self == Color` so a
/// single declaration serves every spelling: `Color.storePrimary`, `let c: Color =
/// .storePrimary`, and `.foregroundStyle(.storePrimary)`.
public extension ShapeStyle where Self == Color {
    // MARK: - Background
    static var storeSectionBackground: Color { bundledColor("storeSectionBackground") }
    static var storeOnSectionBackground: Color { bundledColor("storeOnSectionBackground") }
    static var storeSectionBackgroundVariant: Color { bundledColor("storeSectionBackgroundVariant") }
    static var storeOnSectionBackgroundVariant: Color { bundledColor("storeOnSectionBackgroundVariant") }

    // MARK: - Primary & Secondary
    static var storePrimary: Color { bundledColor("storePrimary") }
    static var storeOnPrimary: Color { bundledColor("storeOnPrimary") }
    static var storeSecondary: Color { bundledColor("storeSecondary") }
    static var storeOnSecondary: Color { bundledColor("storeOnSecondary") }
    static var storePrimaryContainer: Color { bundledColor("storePrimaryContainer") }
    static var storeOnPrimaryContainer: Color { bundledColor("storeOnPrimaryContainer") }
    static var storeSecondaryContainer: Color { bundledColor("storeSecondaryContainer") }
    static var storeOnSecondaryContainer: Color { bundledColor("storeOnSecondaryContainer") }

    // MARK: - Alerts
    static var storeErrorContainer: Color { bundledColor("storeErrorContainer") }
    static var storeOnErrorContainer: Color { bundledColor("storeOnErrorContainer") }
    static var storeWarningContainer: Color { bundledColor("storeWarningContainer") }
    static var storeOnWarningContainer: Color { bundledColor("storeOnWarningContainer") }
    static var storeCautionContainer: Color { bundledColor("storeCautionContainer") }
    static var storeOnCautionContainer: Color { bundledColor("storeOnCautionContainer") }
    static var storeSuccessContainer: Color { bundledColor("storeSuccessContainer") }
    static var storeOnSuccessContainer: Color { bundledColor("storeOnSuccessContainer") }
    static var storeInfoContainer: Color { bundledColor("storeInfoContainer") }
    static var storeOnInfoContainer: Color { bundledColor("storeOnInfoContainer") }
    static var storeNeutralContainer: Color { bundledColor("storeNeutralContainer") }
    static var storeOnNeutralContainer: Color { bundledColor("storeOnNeutralContainer") }
    static var storeAlertRed: Color { bundledColor("storeAlertRed") }
    static var storeOnAlertRed: Color { bundledColor("storeOnAlertRed") }
    static var storeAlertOrange: Color { bundledColor("storeAlertOrange") }
    static var storeOnAlertOrange: Color { bundledColor("storeOnAlertOrange") }
    static var storeAlertGreen: Color { bundledColor("storeAlertGreen") }
    static var storeOnAlertGreen: Color { bundledColor("storeOnAlertGreen") }
    static var storeAlertBlue: Color { bundledColor("storeAlertBlue") }
    static var storeOnAlertBlue: Color { bundledColor("storeOnAlertBlue") }

    // MARK: - Outline
    static var storeOutline: Color { bundledColor("storeOutline") }
    static var storeOutlineVariant: Color { bundledColor("storeOutlineVariant") }

    // MARK: - Surface
    static var storeSurfaceDim: Color { bundledColor("storeSurfaceDim") }
    static var storeSurfaceBright: Color { bundledColor("storeSurfaceBright") }
    static var storeSurface: Color { bundledColor("storeSurface") }
    static var storeSurfaceContainerHighest: Color { bundledColor("storeSurfaceContainerHighest") }
    static var storeOnSurface: Color { bundledColor("storeOnSurface") }
    static var storeOnSurfaceVariant: Color { bundledColor("storeOnSurfaceVariant") }
    static var storeOnSurfaceVariantLowest: Color { bundledColor("storeOnSurfaceVariantLowest") }
    static var storeInverseSurface: Color { bundledColor("storeInverseSurface") }
    static var storeOnInverseSurface: Color { bundledColor("storeOnInverseSurface") }

    // MARK: - Overlay
    static var storeOverlayOpacity20: Color { bundledColor("storeOverlayOpacity20") }
    static var storeOverlayOpacity50: Color { bundledColor("storeOverlayOpacity50") }

    // MARK: - Palette
    static var storePaletteWooBlue20: Color { bundledColor("storePaletteWooBlue20") }
    static var storePaletteWooBlue40: Color { bundledColor("storePaletteWooBlue40") }
    static var storePaletteWooBlue60: Color { bundledColor("storePaletteWooBlue60") }
    static var storePaletteWooGreen20: Color { bundledColor("storePaletteWooGreen20") }
    static var storePaletteWooGreen40: Color { bundledColor("storePaletteWooGreen40") }
    static var storePaletteWooGreen60: Color { bundledColor("storePaletteWooGreen60") }
    static var storePaletteWooOrange20: Color { bundledColor("storePaletteWooOrange20") }
    static var storePaletteWooOrange40: Color { bundledColor("storePaletteWooOrange40") }
    static var storePaletteWooOrange60: Color { bundledColor("storePaletteWooOrange60") }
    static var storePaletteWooPink20: Color { bundledColor("storePaletteWooPink20") }
    static var storePaletteWooPink40: Color { bundledColor("storePaletteWooPink40") }
    static var storePaletteWooPink60: Color { bundledColor("storePaletteWooPink60") }
    static var storePaletteWooPurple0: Color { bundledColor("storePaletteWooPurple0") }
    static var storePaletteWooPurple5: Color { bundledColor("storePaletteWooPurple5") }
    static var storePaletteWooPurple10: Color { bundledColor("storePaletteWooPurple10") }
    static var storePaletteWooPurple20: Color { bundledColor("storePaletteWooPurple20") }
    static var storePaletteWooPurple30: Color { bundledColor("storePaletteWooPurple30") }
    static var storePaletteWooPurple40: Color { bundledColor("storePaletteWooPurple40") }
    static var storePaletteWooPurple50: Color { bundledColor("storePaletteWooPurple50") }
    static var storePaletteWooPurple60: Color { bundledColor("storePaletteWooPurple60") }
    static var storePaletteWooPurple70: Color { bundledColor("storePaletteWooPurple70") }
    static var storePaletteWooPurple80: Color { bundledColor("storePaletteWooPurple80") }
    static var storePaletteWooPurple90: Color { bundledColor("storePaletteWooPurple90") }
    static var storePaletteWooPurple100: Color { bundledColor("storePaletteWooPurple100") }
    static var storePaletteWooSandstone5: Color { bundledColor("storePaletteWooSandstone5") }
    static var storePaletteWooSandstone10: Color { bundledColor("storePaletteWooSandstone10") }
    static var storePaletteWooSandstone20: Color { bundledColor("storePaletteWooSandstone20") }
    static var storePaletteWooSandstone40: Color { bundledColor("storePaletteWooSandstone40") }
    static var storePaletteWooSandstone60: Color { bundledColor("storePaletteWooSandstone60") }
    static var storePaletteGray0: Color { bundledColor("storePaletteGray0") }
    static var storePaletteGray5: Color { bundledColor("storePaletteGray5") }
    static var storePaletteGray10: Color { bundledColor("storePaletteGray10") }
    static var storePaletteGray20: Color { bundledColor("storePaletteGray20") }
    static var storePaletteGray30: Color { bundledColor("storePaletteGray30") }
    static var storePaletteGray40: Color { bundledColor("storePaletteGray40") }
    static var storePaletteGray50: Color { bundledColor("storePaletteGray50") }
    static var storePaletteGray60: Color { bundledColor("storePaletteGray60") }
    static var storePaletteGray70: Color { bundledColor("storePaletteGray70") }
    static var storePaletteGray80: Color { bundledColor("storePaletteGray80") }
    static var storePaletteGray90: Color { bundledColor("storePaletteGray90") }
    static var storePaletteGray100: Color { bundledColor("storePaletteGray100") }

    /// Loads a named color from the design system's asset catalog in this package's bundle.
    private static func bundledColor(_ name: String) -> Color {
        Color(name, bundle: .module)
    }
}

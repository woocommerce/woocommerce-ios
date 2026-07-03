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

    // MARK: - State Layers
    static var storeStateLayerOnSurfaceOpacity08: Color { bundledColor("storeStateLayerOnSurfaceOpacity08") }
    static var storeStateLayerOnSurfaceOpacity10: Color { bundledColor("storeStateLayerOnSurfaceOpacity10") }
    static var storeStateLayerOnSurfaceOpacity16: Color { bundledColor("storeStateLayerOnSurfaceOpacity16") }

    /// Loads a named color from the design system's asset catalog in this package's bundle.
    private static func bundledColor(_ name: String) -> Color {
        Color(name, bundle: .module)
    }
}

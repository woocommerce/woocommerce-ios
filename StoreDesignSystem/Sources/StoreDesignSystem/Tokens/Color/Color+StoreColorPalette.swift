//  Color+StoreColorPalette.swift
//
//  Color roles from the Figma variables export (Mobile Design System).
//  Two tiers per WOOMOB-3558: a raw `Colors` primitive palette (`storePalette…`) and the
//  `Woo theme` semantic roles that reference it. Light + Dark values are both real (from the
//  export); high contrast is intentionally not modeled yet. The `// alias:` comments record the
//  primitive each semantic maps to in Figma — the asset catalog stores flattened values, so these
//  keep the mapping greppable for a future palette refactor. Re-sync from a fresh export on change.

import SwiftUI

/// The design system's color roles. Declared on `ShapeStyle where Self == Color` so a
/// single declaration serves every spelling: `Color.storePrimary`, `let c: Color =
/// .storePrimary`, and `.foregroundStyle(.storePrimary)`.
public extension ShapeStyle where Self == Color {
    // MARK: - Background
    static var storeSectionBackground: Color { bundledColor("storeSectionBackground") } // alias L: raw / D: Gray 100
    static var storeOnSectionBackground: Color { bundledColor("storeOnSectionBackground") } // alias L: raw / D: White
    static var storeSectionBackgroundVariant: Color { bundledColor("storeSectionBackgroundVariant") } // alias L: raw / D: Gray 100
    static var storeOnSectionBackgroundVariant: Color { bundledColor("storeOnSectionBackgroundVariant") }

    // MARK: - Primary & Secondary
    static var storePrimary: Color { bundledColor("storePrimary") } // alias: Purple 40
    static var storeOnPrimary: Color { bundledColor("storeOnPrimary") } // alias: White
    static var storeSecondary: Color { bundledColor("storeSecondary") } // alias L: Purple 60 / D: raw
    static var storeOnSecondary: Color { bundledColor("storeOnSecondary") } // alias L: White / D: raw
    static var storePrimaryContainer: Color { bundledColor("storePrimaryContainer") } // alias L: Purple 20 / D: White
    static var storeOnPrimaryContainer: Color { bundledColor("storeOnPrimaryContainer") } // alias L: Purple 90 / D: White
    static var storeSecondaryContainer: Color { bundledColor("storeSecondaryContainer") } // alias L: Purple 0 / D: Purple 80
    static var storeOnSecondaryContainer: Color { bundledColor("storeOnSecondaryContainer") } // alias L: Purple 40 / D: Purple 20

    // MARK: - Error
    static var storeError: Color { bundledColor("storeError") }
    static var storeOnError: Color { bundledColor("storeOnError") } // alias: White

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
    static var storeOnAlertRed: Color { bundledColor("storeOnAlertRed") } // alias L: White / D: raw
    static var storeAlertOrange: Color { bundledColor("storeAlertOrange") } // alias L: Orange 40 / D: raw
    static var storeOnAlertOrange: Color { bundledColor("storeOnAlertOrange") } // alias L: White / D: raw
    static var storeAlertGreen: Color { bundledColor("storeAlertGreen") }
    static var storeOnAlertGreen: Color { bundledColor("storeOnAlertGreen") } // alias L: White / D: raw
    static var storeAlertBlue: Color { bundledColor("storeAlertBlue") }
    static var storeOnAlertBlue: Color { bundledColor("storeOnAlertBlue") } // alias L: White / D: raw

    // MARK: - Outline
    static var storeOutline: Color { bundledColor("storeOutline") } // alias L: Gray 40 / D: raw
    static var storeOutlineVariant: Color { bundledColor("storeOutlineVariant") } // alias L: Gray 5 / D: raw

    // MARK: - Surface
    static var storeSurfaceDim: Color { bundledColor("storeSurfaceDim") } // alias L: Gray 0 / D: Gray 80
    static var storeSurfaceBright: Color { bundledColor("storeSurfaceBright") } // alias L: White / D: Gray 90
    static var storeSurface: Color { bundledColor("storeSurface") } // alias L: White / D: Gray 100
    static var storeSurfaceContainerHighest: Color { bundledColor("storeSurfaceContainerHighest") } // alias L: Gray 30 / D: Gray 100
    static var storeOnSurface: Color { bundledColor("storeOnSurface") } // alias L: Black / D: White
    static var storeOnSurfaceVariant: Color { bundledColor("storeOnSurfaceVariant") } // alias L: Gray 80 / D: raw
    static var storeOnSurfaceVariantLowest: Color { bundledColor("storeOnSurfaceVariantLowest") } // alias L: Gray 60 / D: Gray 20
    static var storeInverseSurface: Color { bundledColor("storeInverseSurface") } // alias L: Black / D: White
    static var storeOnInverseSurface: Color { bundledColor("storeOnInverseSurface") } // alias L: White / D: Black

    // MARK: - Overlay
    static var storeOverlayOpacity20: Color { bundledColor("storeOverlayOpacity20") }
    static var storeOverlayOpacity50: Color { bundledColor("storeOverlayOpacity50") }

    // MARK: - State Layers
    static var storeStateLayerOnSurfaceOpacity08: Color { bundledColor("storeStateLayerOnSurfaceOpacity08") }
    static var storeStateLayerOnSurfaceOpacity10: Color { bundledColor("storeStateLayerOnSurfaceOpacity10") }
    static var storeStateLayerOnSurfaceOpacity16: Color { bundledColor("storeStateLayerOnSurfaceOpacity16") }
    static var storeStateLayerOnSurfaceOpacity24: Color { bundledColor("storeStateLayerOnSurfaceOpacity24") }

    // MARK: - Tint Layers
    static var storeTintLayerPrimaryContainerOpacity08: Color { bundledColor("storeTintLayerPrimaryContainerOpacity08") }
    static var storeTintLayerPrimaryContainerOpacity10: Color { bundledColor("storeTintLayerPrimaryContainerOpacity10") }
    static var storeTintLayerPrimaryContainerOpacity16: Color { bundledColor("storeTintLayerPrimaryContainerOpacity16") }
    static var storeTintLayerPrimaryContainerOpacity24: Color { bundledColor("storeTintLayerPrimaryContainerOpacity24") }

    // MARK: - Palette (primitives)
    static var storePaletteWhite: Color { bundledColor("storePaletteWhite") }
    static var storePaletteBlack: Color { bundledColor("storePaletteBlack") }
    static var storePaletteBlue20: Color { bundledColor("storePaletteBlue20") }
    static var storePaletteBlue40: Color { bundledColor("storePaletteBlue40") }
    static var storePaletteBlue60: Color { bundledColor("storePaletteBlue60") }
    static var storePaletteGreen20: Color { bundledColor("storePaletteGreen20") }
    static var storePaletteGreen40: Color { bundledColor("storePaletteGreen40") }
    static var storePaletteGreen60: Color { bundledColor("storePaletteGreen60") }
    static var storePaletteOrange20: Color { bundledColor("storePaletteOrange20") }
    static var storePaletteOrange40: Color { bundledColor("storePaletteOrange40") }
    static var storePaletteOrange60: Color { bundledColor("storePaletteOrange60") }
    static var storePalettePink20: Color { bundledColor("storePalettePink20") }
    static var storePalettePink40: Color { bundledColor("storePalettePink40") }
    static var storePalettePink60: Color { bundledColor("storePalettePink60") }
    static var storePalettePurple0: Color { bundledColor("storePalettePurple0") }
    static var storePalettePurple5: Color { bundledColor("storePalettePurple5") }
    static var storePalettePurple10: Color { bundledColor("storePalettePurple10") }
    static var storePalettePurple20: Color { bundledColor("storePalettePurple20") }
    static var storePalettePurple30: Color { bundledColor("storePalettePurple30") }
    static var storePalettePurple40: Color { bundledColor("storePalettePurple40") }
    static var storePalettePurple50: Color { bundledColor("storePalettePurple50") }
    static var storePalettePurple60: Color { bundledColor("storePalettePurple60") }
    static var storePalettePurple70: Color { bundledColor("storePalettePurple70") }
    static var storePalettePurple80: Color { bundledColor("storePalettePurple80") }
    static var storePalettePurple90: Color { bundledColor("storePalettePurple90") }
    static var storePalettePurple100: Color { bundledColor("storePalettePurple100") }
    static var storePaletteSandstone5: Color { bundledColor("storePaletteSandstone5") }
    static var storePaletteSandstone10: Color { bundledColor("storePaletteSandstone10") }
    static var storePaletteSandstone20: Color { bundledColor("storePaletteSandstone20") }
    static var storePaletteSandstone40: Color { bundledColor("storePaletteSandstone40") }
    static var storePaletteSandstone60: Color { bundledColor("storePaletteSandstone60") }
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

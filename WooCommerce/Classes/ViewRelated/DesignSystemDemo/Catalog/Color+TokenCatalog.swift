//  Color+TokenCatalog.swift
//
//  Generated with Claude from the StoreDesignSystem token definitions.
//
//  Enumerates the design tokens of this type for the in-app Design System demo. Gated to
//  non-production builds so it never ships in the App Store binary.

#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct StoreColorToken: Identifiable {
    let name: String
    let color: Color
    var id: String { name }
}

extension Color {
    static let storeColorCatalog: [StoreColorToken] = [
        StoreColorToken(name: "storeInteractivePrimary", color: .storeInteractivePrimary),
        StoreColorToken(name: "storeInteractiveDestructive", color: .storeInteractiveDestructive),
        StoreColorToken(name: "storePrimaryPressed", color: .storePrimaryPressed),
        StoreColorToken(name: "storeTextPrimary", color: .storeTextPrimary),
        StoreColorToken(name: "storeTextSecondary", color: .storeTextSecondary),
        StoreColorToken(name: "storeTextTertiary", color: .storeTextTertiary),
        StoreColorToken(name: "storeTextDisabled", color: .storeTextDisabled),
        StoreColorToken(name: "storeTextOnPrimary", color: .storeTextOnPrimary),
        StoreColorToken(name: "storeIconPrimary", color: .storeIconPrimary),
        StoreColorToken(name: "storeSurfacePrimary", color: .storeSurfacePrimary),
        StoreColorToken(name: "storeSurfaceSecondary", color: .storeSurfaceSecondary),
        StoreColorToken(name: "storeSurfaceOverlay", color: .storeSurfaceOverlay),
        StoreColorToken(name: "storeBorderDefault", color: .storeBorderDefault),
        StoreColorToken(name: "storeBorderFocused", color: .storeBorderFocused),
        StoreColorToken(name: "storeStatusSuccess", color: .storeStatusSuccess),
        StoreColorToken(name: "storeStatusError", color: .storeStatusError),
        StoreColorToken(name: "storeStatusWarning", color: .storeStatusWarning),
        StoreColorToken(name: "storeLabelPrimary", color: .storeLabelPrimary),
        StoreColorToken(name: "storeLabelSecondary", color: .storeLabelSecondary),
        StoreColorToken(name: "storeLabelTertiary", color: .storeLabelTertiary),
        StoreColorToken(name: "storeLabelDisabled", color: .storeLabelDisabled),
        StoreColorToken(name: "storeLabelOnPrimary", color: .storeLabelOnPrimary),
    ]
}
#endif

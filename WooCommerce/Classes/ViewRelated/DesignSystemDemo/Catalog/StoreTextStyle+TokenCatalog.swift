//  StoreTextStyle+TokenCatalog.swift
//
//  Generated with Claude from the StoreDesignSystem token definitions.
//
//  Enumerates the design tokens of this type for the in-app Design System demo. Gated to
//  non-production builds so it never ships in the App Store binary.

#if DEBUG || ALPHA
import SwiftUI
import StoreDesignSystem

struct StoreTextStyleToken: Identifiable {
    let name: String
    let style: StoreTextStyle
    var id: String { name }
}

extension StoreTextStyle {
    static let catalog: [StoreTextStyleToken] = [
        StoreTextStyleToken(name: "displayLarge", style: .displayLarge),
        StoreTextStyleToken(name: "displayMedium", style: .displayMedium),
        StoreTextStyleToken(name: "displaySmall", style: .displaySmall),
        StoreTextStyleToken(name: "headlineLarge", style: .headlineLarge),
        StoreTextStyleToken(name: "headlineMedium", style: .headlineMedium),
        StoreTextStyleToken(name: "headlineSmall", style: .headlineSmall),
        StoreTextStyleToken(name: "titleLarge", style: .titleLarge),
        StoreTextStyleToken(name: "titleMedium", style: .titleMedium),
        StoreTextStyleToken(name: "titleSmall", style: .titleSmall),
        StoreTextStyleToken(name: "labelLarge", style: .labelLarge),
        StoreTextStyleToken(name: "labelMedium", style: .labelMedium),
        StoreTextStyleToken(name: "labelSmall", style: .labelSmall),
        StoreTextStyleToken(name: "bodyLarge", style: .bodyLarge),
        StoreTextStyleToken(name: "bodyMedium", style: .bodyMedium),
        StoreTextStyleToken(name: "bodySmall", style: .bodySmall),
    ]
}
#endif

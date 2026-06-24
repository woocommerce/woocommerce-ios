//  StoreCatalog.swift
//
//  DEBUG-only enumeration of design tokens, for the in-app token gallery. These widen
//  the API ONLY in Debug builds (incl. PR / installable builds) — release builds never
//  see them, so the production token surface stays minimal. The token types themselves
//  remain closed-for-construction; these catalogs just list what exists.
//
//  Token-type catalog `all` lists live here (hand-written for typography) and in
//  StoreCatalog.generated.swift (color + icons, generated from the committed Swift).

#if DEBUG
import SwiftUI

// MARK: - Catalog entry types

public struct StoreColorToken: Identifiable {
    public let name: String
    public let color: Color
    public var id: String { name }
}

public struct StoreIconStyleVariant: Identifiable {
    public let style: String
    public let image: StoreIconImage
    public var id: String { style }
}

public struct StoreIconToken: Identifiable {
    public let name: String
    public let variants: [StoreIconStyleVariant]
    public var id: String { name }
}

public struct StoreTextStyleToken: Identifiable {
    public let name: String
    public let style: StoreTextStyle
    public var id: String { name }
}

// MARK: - Typography catalog (hand-maintained — mirrors StoreTextStyle presets)

public enum StoreTextStyleCatalog {
    public static let all: [StoreTextStyleToken] = [
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
        StoreTextStyleToken(name: "bodySmall", style: .bodySmall)
    ]
}

// MARK: - Scalar catalogs (hand-maintained)

public struct StoreScalarToken: Identifiable {
    public let name: String
    public let value: CGFloat
    public var id: String { name }
}

public enum StoreIconSizeCatalog {
    public static let all: [StoreScalarToken] = [
        StoreScalarToken(name: "extraSmall", value: StoreIconSize.extraSmall),
        StoreScalarToken(name: "small", value: StoreIconSize.small),
        StoreScalarToken(name: "medium", value: StoreIconSize.medium),
        StoreScalarToken(name: "large", value: StoreIconSize.large),
        StoreScalarToken(name: "largeIncreased", value: StoreIconSize.largeIncreased),
        StoreScalarToken(name: "extraLarge", value: StoreIconSize.extraLarge)
    ]
}
#endif

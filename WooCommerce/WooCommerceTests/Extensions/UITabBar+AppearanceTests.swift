import StoreDesignSystem
import SwiftUI
import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct UITabBarAppearanceTests {
    @Test func test_woo_appearance_uses_native_surfaces_and_store_design_system_item_palette() {
        // Given
        let expectedItemColor = UIColor(Color.storeOnSurface)
        let expectedBadgeBackgroundColor = UIColor(Color.storeAlertRed)
        let expectedBadgeTextColor = UIColor(Color.storeOnError)

        // When
        let appearance = UITabBar.wooAppearance(usesStoreDesignSystem: true)

        // Then
        #expect(appearance.backgroundColor == nil)
        #expect(appearance.backgroundEffect != nil)
        #expect(appearance.selectionIndicatorTintColor == nil)
        for itemAppearance in [
            appearance.inlineLayoutAppearance,
            appearance.stackedLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            for stateAppearance in [
                itemAppearance.normal,
                itemAppearance.selected,
                itemAppearance.focused
            ] {
                #expect(stateAppearance.iconColor == expectedItemColor)
                #expect(stateAppearance.titleTextAttributes[.foregroundColor] as? UIColor == expectedItemColor)
            }
            for stateAppearance in [
                itemAppearance.normal,
                itemAppearance.selected,
                itemAppearance.disabled
            ] {
                #expect(stateAppearance.badgeBackgroundColor == expectedBadgeBackgroundColor)
                #expect(stateAppearance.badgeTextAttributes[.foregroundColor] as? UIColor == expectedBadgeTextColor)
            }
        }
    }

    @Test func test_woo_appearance_store_design_system_item_palette_adapts_to_light_and_dark_mode() throws {
        // Given
        let lightTraits = UITraitCollection(userInterfaceStyle: .light)
        let darkTraits = UITraitCollection(userInterfaceStyle: .dark)

        // When
        let appearance = UITabBar.wooAppearance(usesStoreDesignSystem: true)
        let itemColor = try #require(appearance.stackedLayoutAppearance.normal.iconColor)

        // Then
        #expect(itemColor.resolvedColor(with: lightTraits) ==
                UIColor(Color.storeOnSurface).resolvedColor(with: lightTraits))
        #expect(itemColor.resolvedColor(with: darkTraits) ==
                UIColor(Color.storeOnSurface).resolvedColor(with: darkTraits))
        #expect(itemColor.resolvedColor(with: lightTraits) != itemColor.resolvedColor(with: darkTraits))
    }

    @Test func test_woo_appearance_uses_legacy_colors_when_store_design_system_is_disabled() {
        // When
        let appearance = UITabBar.wooAppearance(usesStoreDesignSystem: false)

        // Then
        #expect(appearance.backgroundColor == nil)
        #expect(appearance.selectionIndicatorTintColor == nil)
        for itemAppearance in [
            appearance.inlineLayoutAppearance,
            appearance.stackedLayoutAppearance,
            appearance.compactInlineLayoutAppearance
        ] {
            for stateAppearance in [
                itemAppearance.normal,
                itemAppearance.selected,
                itemAppearance.disabled
            ] {
                #expect(stateAppearance.badgeBackgroundColor == .primary)
                #expect(stateAppearance.badgeTextAttributes[.foregroundColor] as? UIColor == .white)
            }
        }
    }
}

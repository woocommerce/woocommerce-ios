import StoreDesignSystem
import SwiftUI
import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct OrdersProductsListHeaderStyleTests {
    @Test func test_configure_navigation_appearance_uses_store_design_system_title_colors_when_header_is_visible() {
        guard #available(iOS 26.0, *) else { return }

        // Given
        let navigationItem = UINavigationItem()
        let scrollView = UIScrollView()

        // When
        OrdersProductsListHeaderStyle.configureNavigationAppearance(navigationItem: navigationItem,
                                                                     scrollView: scrollView,
                                                                     usesStoreDesignSystem: true)

        // Then
        let expectedColor = UIColor(Color.storeOnSurface)
        for appearance in [
            navigationItem.standardAppearance,
            navigationItem.scrollEdgeAppearance,
            navigationItem.compactAppearance,
            navigationItem.compactScrollEdgeAppearance
        ] {
            #expect(appearance?.titleTextAttributes[.foregroundColor] as? UIColor == expectedColor)
            #expect(appearance?.largeTitleTextAttributes[.foregroundColor] as? UIColor == expectedColor)
        }
        #expect(scrollView.topEdgeEffect.isHidden)
    }

    @Test func test_configure_navigation_appearance_restores_native_appearance_when_header_is_hidden() {
        guard #available(iOS 26.0, *) else { return }

        // Given
        let navigationItem = UINavigationItem()
        let scrollView = UIScrollView()

        // When
        OrdersProductsListHeaderStyle.configureNavigationAppearance(navigationItem: navigationItem,
                                                                     scrollView: scrollView,
                                                                     isHeaderVisible: false,
                                                                     usesStoreDesignSystem: true)

        // Then
        #expect(navigationItem.standardAppearance == nil)
        #expect(navigationItem.scrollEdgeAppearance == nil)
        #expect(navigationItem.compactAppearance == nil)
        #expect(navigationItem.compactScrollEdgeAppearance == nil)
        #expect(scrollView.topEdgeEffect.isHidden == false)
    }

    @Test func test_configure_navigation_appearance_preserves_legacy_title_colors_when_store_design_system_is_disabled() {
        guard #available(iOS 26.0, *) else { return }

        // Given
        let navigationItem = UINavigationItem()
        let scrollView = UIScrollView()
        let expectedAppearance = UINavigationBarAppearance()
        expectedAppearance.configureWithTransparentBackground()

        // When
        OrdersProductsListHeaderStyle.configureNavigationAppearance(navigationItem: navigationItem,
                                                                     scrollView: scrollView,
                                                                     usesStoreDesignSystem: false)

        // Then
        #expect(navigationItem.standardAppearance?.titleTextAttributes[.foregroundColor] as? UIColor ==
                expectedAppearance.titleTextAttributes[.foregroundColor] as? UIColor)
        #expect(navigationItem.standardAppearance?.largeTitleTextAttributes[.foregroundColor] as? UIColor ==
                expectedAppearance.largeTitleTextAttributes[.foregroundColor] as? UIColor)
    }
}

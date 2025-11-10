import Foundation
import SwiftUI
import Testing
import enum WooFoundationCore.CurrencyCode
import Yosemite
@testable import PointOfSale

struct PointOfSaleDashboardViewHelperTests {
    // MARK: - Horizontal Size Class Tests

    @Test func determineViewState_when_horizontalSizeClass_is_compact_returns_unsupportedWidth() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .unsupportedWidth)
    }

    @Test func determineViewState_when_horizontalSizeClass_is_nil_returns_unsupportedWidth() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass? = nil

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .unsupportedWidth)
    }

    // MARK: - Eligibility State Tests

    @Test func determineViewState_when_eligibilityState_is_nil_returns_loading() async throws {
        // Given
        let eligibilityState: POSEligibilityState? = nil
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .loading())
    }

    @Test(arguments: [
        POSIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "9.6.0"),
        POSIneligibleReason.unsupportedCurrency(countryCode: .US, supportedCurrencies: [.USD, .GBP]),
        POSIneligibleReason.siteSettingsNotAvailable,
        POSIneligibleReason.wooCommercePluginNotFound,
        POSIneligibleReason.featureSwitchDisabled,
        POSIneligibleReason.selfDeallocated
    ])
    func determineViewState_when_ineligible_returns_ineligible(reason: POSIneligibleReason) async throws {
        // Given
        let eligibilityState: POSEligibilityState = .ineligible(reason: reason)
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .ineligible(reason: reason))
    }

    // MARK: - Eligible State Tests

    @Test func determineViewState_when_eligible_and_loading_returns_loading() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .loading()
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .loading())
    }

    @Test func determineViewState_when_eligible_and_content_returns_content() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .content)
    }

    // MARK: - Error State Tests

    @Test(arguments: [
        PointOfSaleErrorState.errorOnLoadingProducts(),
        PointOfSaleErrorState.errorOnLoadingVariations(),
        PointOfSaleErrorState.errorOnLoadingCoupons(),
        PointOfSaleErrorState.errorCouponsDisabled,
        PointOfSaleErrorState.errorOnLoadingProductsNextPage(),
        PointOfSaleErrorState.errorOnLoadingVariationsNextPage(),
        PointOfSaleErrorState.errorOnLoadingCouponsNextPage(),
        PointOfSaleErrorState.errorOnRefreshingCoupons(),
        PointOfSaleErrorState.errorOnEnablingCoupons()
    ])
    func determineViewState_when_eligible_and_error_returns_error(errorState: PointOfSaleErrorState) async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .error(errorState)
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .error(errorState))
    }

    // MARK: - Priority Tests

    @Test func determineViewState_horizontalSizeClass_takes_priority_over_eligibility_state() async throws {
        // Given - compact size class should return unsupportedWidth regardless of eligibility
        let eligibilityState: POSEligibilityState = .ineligible(reason: .featureSwitchDisabled)
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .unsupportedWidth)
    }

    @Test func determineViewState_nil_eligibilityState_takes_priority_over_containerState() async throws {
        // Given - nil eligibility should return loading regardless of container state
        let eligibilityState: POSEligibilityState? = nil
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .loading())
    }

    @Test func determineViewState_ineligible_state_takes_priority_over_containerState() async throws {
        // Given - ineligible state should return ineligible regardless of container state
        let eligibilityState: POSEligibilityState = .ineligible(reason: .featureSwitchDisabled)
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .regular

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            horizontalSizeClass: horizontalSizeClass
        )

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    // MARK: - Floating Control Tests

    @Test(arguments: [
        (PointOfSaleDashboardView.ViewState.content, true),
        (PointOfSaleDashboardView.ViewState.error(PointOfSaleErrorState.errorOnLoadingProducts()), true),
        (PointOfSaleDashboardView.ViewState.unsupportedWidth, true)
    ])
    func showsFloatingControl_when_content_error_or_unsupportedWidth_returns_true(viewState: PointOfSaleDashboardView.ViewState, expected: Bool) async throws {
        // When & Then
        #expect(viewState.showsFloatingControl == expected)
    }

    @Test(arguments: [
        (PointOfSaleDashboardView.ViewState.loading(), false),
        (PointOfSaleDashboardView.ViewState.ineligible(reason: .featureSwitchDisabled), false)
    ])
    func showsFloatingControl_when_loading_or_ineligible_returns_false(viewState: PointOfSaleDashboardView.ViewState, expected: Bool) async throws {
        // When & Then
        #expect(viewState.showsFloatingControl == expected)
    }
}

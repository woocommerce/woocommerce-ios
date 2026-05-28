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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
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
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    // MARK: - Phone Prototype Flag Tests

    @Test func determineViewState_when_phonePrototype_flag_enabled_and_compact_returns_content() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: true
        )

        // Then
        #expect(result == .content)
    }

    @Test func determineViewState_when_phonePrototype_flag_enabled_and_nil_sizeClass_returns_content() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass? = nil

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: true
        )

        // Then
        #expect(result == .content)
    }

    @Test func determineViewState_when_phonePrototype_flag_enabled_and_ineligible_returns_ineligible() async throws {
        // Given
        let eligibilityState: POSEligibilityState = .ineligible(reason: .featureSwitchDisabled)
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: true
        )

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    @Test func determineViewState_when_phonePrototype_flag_enabled_and_nil_eligibility_returns_loading() async throws {
        // Given
        let eligibilityState: POSEligibilityState? = nil
        let itemsContainerState: ItemsContainerState = .content
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: true
        )

        // Then
        #expect(result == .loading())
    }

    @Test(arguments: [
        PointOfSaleErrorState.errorOnLoadingProducts(),
        PointOfSaleErrorState.errorOnLoadingVariations(),
        PointOfSaleErrorState.errorOnLoadingCoupons()
    ])
    func determineViewState_when_phonePrototype_flag_enabled_and_error_returns_error(errorState: PointOfSaleErrorState) async throws {
        // Given
        let eligibilityState: POSEligibilityState = .eligible
        let itemsContainerState: ItemsContainerState = .error(errorState)
        let horizontalSizeClass: UserInterfaceSizeClass = .compact

        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: eligibilityState,
            itemsContainerState: itemsContainerState,
            pinStatus: .absent,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: true
        )

        // Then
        #expect(result == .error(errorState))
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
        (PointOfSaleDashboardView.ViewState.ineligible(reason: .featureSwitchDisabled), false),
        (PointOfSaleDashboardView.ViewState.locked, false)
    ])
    func showsFloatingControl_when_loading_ineligible_or_locked_returns_false(viewState: PointOfSaleDashboardView.ViewState, expected: Bool) async throws {
        // When & Then
        #expect(viewState.showsFloatingControl == expected)
    }

    @Test func showsFloatingControl_when_error_is_staffLoadError_returns_false() async throws {
        // When & Then - staff load errors hide the floating control like initial catalog sync errors.
        let viewState = PointOfSaleDashboardView.ViewState.error(PointOfSaleErrorState.errorOnLoadingStaff())
        #expect(viewState.showsFloatingControl == false)
    }

    // MARK: - Staff Gate Tests

    @Test func determineViewState_when_pinStatus_is_unknown_and_not_refreshing_returns_staffLoadError() async throws {
        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .content,
            pinStatus: .unknown,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        if case .error(let errorState) = result {
            #expect(errorState.errorType == .staffLoadError)
        } else {
            Issue.record("Expected .error(.staffLoadError), got \(result)")
        }
    }

    @Test func determineViewState_when_pinStatus_is_unknown_and_refreshing_returns_loading() async throws {
        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .content,
            pinStatus: .unknown,
            isLocked: true,
            isStaffRefreshing: true,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .loading())
    }

    @Test func determineViewState_when_items_loading_and_staff_unknown_returns_items_loading() async throws {
        // Given
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .loading(isCatalogSyncing: true),
            pinStatus: .unknown,
            isLocked: true,
            isStaffRefreshing: true,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .loading(isCatalogSyncing: true))
    }

    @Test func determineViewState_when_items_error_and_staff_unknown_returns_items_error() async throws {
        // Given - items error must win over staff error so the user sees the real failure.
        let itemsError = PointOfSaleErrorState.errorOnLoadingProducts()
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .error(itemsError),
            pinStatus: .unknown,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .error(itemsError))
    }

    @Test func determineViewState_when_ineligible_and_staff_unknown_returns_ineligible() async throws {
        // Given
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .ineligible(reason: .featureSwitchDisabled),
            itemsContainerState: .content,
            pinStatus: .unknown,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .ineligible(reason: .featureSwitchDisabled))
    }

    // MARK: - Lock Gate Tests

    @Test func determineViewState_when_eligible_content_and_locked_with_present_pin_returns_locked() async throws {
        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .content,
            pinStatus: .present,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .locked)
    }

    @Test func determineViewState_when_locked_with_absent_pin_returns_content() async throws {
        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .content,
            pinStatus: .absent,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .content)
    }

    @Test func determineViewState_when_unlocked_with_present_pin_returns_content() async throws {
        // When
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .content,
            pinStatus: .present,
            isLocked: false,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .content)
    }

    @Test func determineViewState_when_items_loading_takes_priority_over_lock() async throws {
        // Given - lock gate fires only after items resolve to .content.
        let result = PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: .eligible,
            itemsContainerState: .loading(isCatalogSyncing: false),
            pinStatus: .present,
            isLocked: true,
            isStaffRefreshing: false,
            horizontalSizeClass: .regular,
            isPhonePrototypeEnabled: false
        )

        // Then
        #expect(result == .loading())
    }
}

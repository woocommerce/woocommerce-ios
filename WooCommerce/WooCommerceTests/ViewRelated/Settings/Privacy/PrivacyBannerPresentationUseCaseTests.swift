import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

final class PrivacyBannerPresentationUseCaseTests: XCTestCase {

    @MainActor func test_show_banner_is_true_when_user_is_in_EU_and_choices_havent_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        // Iterate through all of the country codes
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        for euCode in Country.GDPRCountryCodes {
            stores.whenReceivingAction(ofType: UserAction.self) { action in
                switch action {
                case .fetchUserIPCountryCode(let onCompletion):
                    onCompletion(.success(euCode))
                default:
                    break
                }
            }

            // When
            let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores)
            let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

            // Then
            XCTAssertTrue(shouldShowBanner)
        }
    }

    @MainActor func test_show_banner_is_false_when_user_is_outside_of_EU_and_choices_have_not_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        stores.whenReceivingAction(ofType: UserAction.self) { action in
            switch action {
            case .fetchUserIPCountryCode(let onCompletion):
                onCompletion(.success("US"))
            default:
                break
            }
        }

        // When
        let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores)
        let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

        // Then
        XCTAssertFalse(shouldShowBanner)
    }

    @MainActor func test_show_banner_is_false_when_choices_have_been_saved() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = true

        // When
        let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores)
        let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

        // Then
        XCTAssertFalse(shouldShowBanner)
    }
}

import XCTest
import TestKit

@testable import WooCommerce
@testable import Yosemite

final class PrivacyBannerPresentationUseCaseTests: XCTestCase {

    @MainActor func test_show_banner_is_true_when_WPCOM_user_is_in_EU_and_choices_havent_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        // Iterate through all of the country codes
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        for euCode in Country.GDPRCountryCodes {
            stores.whenReceivingAction(ofType: AccountAction.self) { action in
                switch action {
                case .synchronizeAccount(let onCompletion):
                    let account = Account(userID: 123, displayName: "", email: "", username: "", gravatarUrl: "", ipCountryCode: euCode)
                    onCompletion(.success(account))
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

    @MainActor func test_show_banner_is_false_when_WPCOM_user_is_outside_of_EU_and_choices_have_not_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .synchronizeAccount(let onCompletion):
                let account = Account(userID: 123, displayName: "", email: "", username: "", gravatarUrl: "", ipCountryCode: "US")
                onCompletion(.success(account))
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

    @MainActor func test_show_banner_is_false_when_WPCOM_user_is_inside_of_EU_and_choices_have_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: true))
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case .synchronizeAccount(let onCompletion):
                let account = Account(userID: 123, displayName: "", email: "", username: "", gravatarUrl: "", ipCountryCode: "GB")
                onCompletion(.success(account))
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

    @MainActor func test_show_banner_is_true_when_non_WPCOM_user_has_EU_locale_and_choices_have_not_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))

        // When
        let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores, currentLocale: .init(identifier: "en_GB"))
        let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

        // Then
        XCTAssertTrue(shouldShowBanner)
    }

    @MainActor func test_show_banner_is_false_when_non_WPCOM_user_has_none_EU_locale_and_choices_have_not_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = false

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))

        // When
        let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores, currentLocale: .init(identifier: "en_US"))
        let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

        // Then
        XCTAssertFalse(shouldShowBanner)
    }

    @MainActor func test_show_banner_is_false_when_non_WPCOM_user_has_EU_locale_and_choices_have_been_saved() async throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TestingSuite"))
        defaults[.hasSavedPrivacyBannerSettings] = true

        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, isWPCom: false))

        // When
        let useCase = PrivacyBannerPresentationUseCase(defaults: defaults, stores: stores, currentLocale: .init(identifier: "en_GB"))
        let shouldShowBanner = await useCase.shouldShowPrivacyBanner()

        // Then
        XCTAssertFalse(shouldShowBanner)
    }

    override class func tearDown() {
        super.tearDown()
        SessionManager.removeTestingDatabase()
    }
}

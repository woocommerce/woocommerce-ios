import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeEligibilityCheckerTests: XCTestCase {
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        ServiceLocator.setStores(stores)
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    // MARK: - `isSiteEligible` for site
    @MainActor
    func test_isEligible_is_true_when_authenticated_with_wpcom_and_feature_flag_enabled_and_blaze_approved() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: true)
        mockRemoteFeatureFlag(isEnabled: true)
        let checker = BlazeEligibilityChecker(stores: stores)

        // When
        let isEligible = await checker.isSiteEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    @MainActor
    func test_isEligible_is_false_when_authenticated_without_wpcom() async {
        // Given
        mockDefaultSite(isEligibleForBlaze: true)
        let nonWPCOMCredentialsValues: [Credentials] = [
            .applicationPassword(username: "", password: "", siteAddress: ""),
            .wporg(username: "", password: "", siteAddress: "")
        ]

        for nonWPCOMCredentials in nonWPCOMCredentialsValues {
            stores.authenticate(credentials: nonWPCOMCredentials)
            let checker = BlazeEligibilityChecker(stores: stores)

            // When
            let isEligible = await checker.isSiteEligible()

            // Then
            XCTAssertFalse(isEligible)
        }
    }

    @MainActor
    func test_isEligible_is_false_when_remote_feature_is_disabled() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: true)
        mockRemoteFeatureFlag(isEnabled: false)
        let checker = BlazeEligibilityChecker(stores: stores)

        // When
        let isEligible = await checker.isSiteEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    @MainActor
    func test_isEligible_is_false_when_blaze_is_not_approved() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: false)
        mockRemoteFeatureFlag(isEnabled: true)
        let checker = BlazeEligibilityChecker(stores: stores)

        // When
        let isEligible = await checker.isSiteEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    @MainActor
    func test_isEligible_is_false_when_site_user_is_not_admin() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: true, isAdmin: false)
        mockRemoteFeatureFlag(isEnabled: true)
        let checker = BlazeEligibilityChecker(stores: stores)

        // When
        let isEligible = await checker.isSiteEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    // MARK: - `isProductEligible`
    @MainActor
    func test_isProductEligible_is_true_when_wpcom_auth_and_feature_flag_enabled_and_blaze_approved_and_product_public_without_password() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: true)
        mockRemoteFeatureFlag(isEnabled: true)
        let checker = BlazeEligibilityChecker(stores: stores)
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)

        // When
        let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: false)

        // Then
        XCTAssertTrue(isEligible)
    }

    @MainActor
    func test_isProductEligible_is_false_when_product_is_not_public() async {
        // Given
        let nonPublicStatuses: [ProductStatus] = [.draft, .pending, .privateStatus, .autoDraft, .custom("status")]
        let checker = BlazeEligibilityChecker(stores: stores)

        for nonPublicStatus in nonPublicStatuses {
            let product = Product.fake().copy(statusKey: nonPublicStatus.rawValue)

            // When
            let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: false)

            // Then
            XCTAssertFalse(isEligible)
        }
    }

    @MainActor
    func test_isProductEligible_is_false_when_product_is_password_protected() async {
        // Given
        let checker = BlazeEligibilityChecker(stores: stores)
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)

        // When
        let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: true)

        // Then
        XCTAssertFalse(isEligible)
    }

    @MainActor
    func test_isProductEligible_is_false_when_authenticated_without_wpcom() async {
        // Given
        let nonWPCOMCredentialsValues: [Credentials] = [
            .applicationPassword(username: "", password: "", siteAddress: ""),
            .wporg(username: "", password: "", siteAddress: "")
        ]
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)

        for nonWPCOMCredentials in nonWPCOMCredentialsValues {
            stores.authenticate(credentials: nonWPCOMCredentials)
            let checker = BlazeEligibilityChecker(stores: stores)

            // When
            let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: false)

            // Then
            XCTAssertFalse(isEligible)
        }
    }

    @MainActor
    func test_isProductEligible_is_false_when_remote_feature_is_disabled() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockRemoteFeatureFlag(isEnabled: false)
        let checker = BlazeEligibilityChecker(stores: stores)
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)

        // When
        let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: false)

        // Then
        XCTAssertFalse(isEligible)
    }

    @MainActor
    func test_isProductEligible_is_false_when_blaze_is_not_approved() async {
        // Given
        stores.authenticate(credentials: .wpcom(username: "", authToken: "", siteAddress: ""))
        mockDefaultSite(isEligibleForBlaze: false)
        mockRemoteFeatureFlag(isEnabled: true)
        let checker = BlazeEligibilityChecker(stores: stores)
        let product = Product.fake().copy(statusKey: ProductStatus.published.rawValue)

        // When
        let isEligible = await checker.isProductEligible(product: EditableProductModel(product: product), isPasswordProtected: false)

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension BlazeEligibilityCheckerTests {
    func mockDefaultSite(isEligibleForBlaze: Bool, isAdmin: Bool = true) {
        stores.updateDefaultStore(storeID: 134)
        stores.updateDefaultStore(.fake().copy(siteID: 134,
                                               canBlaze: isEligibleForBlaze,
                                               isAdmin: isAdmin))
    }

    func mockRemoteFeatureFlag(isEnabled: Bool) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            guard case let .isRemoteFeatureFlagEnabled(_, _, completion) = action else {
                return  XCTFail()
            }
            completion(isEnabled)
        }
    }
}

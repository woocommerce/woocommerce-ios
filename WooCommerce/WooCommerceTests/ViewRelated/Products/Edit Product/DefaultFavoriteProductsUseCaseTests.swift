import XCTest
import Yosemite
@testable import WooCommerce

final class DefaultFavoriteProductsUseCaseTests: XCTestCase {
    private let sampleSiteID: Int64 = 134
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        stores = nil
        super.tearDown()
    }

    @MainActor
    func test_it_sets_product_id_as_favorite_in_app_settings() async {
        // Given
        let usecase = DefaultFavoriteProductsUseCase(siteID: sampleSiteID,
                                                       stores: stores)

        var receivedProductID: Int64?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .setProductIDAsFavorite(id, _):
                receivedProductID = id
            default:
                break
            }
        }

        // When
        usecase.markAsFavorite(productID: 4)

        // Then
        XCTAssertEqual(receivedProductID, 4)
    }

    @MainActor
    func test_it_removes_product_id_as_favorite_in_app_settings() async {
        // Given
        let usecase = DefaultFavoriteProductsUseCase(siteID: sampleSiteID,
                                                       stores: stores)

        var receivedProductID: Int64?
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .removeProductIDAsFavorite(id, _):
                receivedProductID = id
            default:
                break
            }
        }

        // When
        usecase.removeFromFavorite(productID: 4)

        // Then
        XCTAssertEqual(receivedProductID, 4)
    }

    @MainActor
    func test_isFavorite_returns_true_when_app_settings_has_the_given_id() async {
        // Given
        let usecase = DefaultFavoriteProductsUseCase(siteID: sampleSiteID,
                                                       stores: stores)
        mockLoadFavoriteProductIDs([1, 2, 3, 4])

        // When
        let isFavorite = await usecase.isFavorite(productID: 4)

        // Then
        XCTAssertTrue(isFavorite)
    }

    @MainActor
    func test_isFavorite_returns_false_when_app_settings_has_the_given_id() async {
        // Given
        let usecase = DefaultFavoriteProductsUseCase(siteID: sampleSiteID,
                                                       stores: stores)
        mockLoadFavoriteProductIDs([1, 2, 3, 4])

        // When
        let isFavorite = await usecase.isFavorite(productID: 5)

        // Then
        XCTAssertFalse(isFavorite)
    }

    @MainActor
    func test_favoriteProductIDs_returns_stored_product_ids_from_app_settings() async {
        // Given
        let usecase = DefaultFavoriteProductsUseCase(siteID: sampleSiteID,
                                                       stores: stores)
        let sampleProductIDs: [Int64] = [1, 2, 3, 4]
        mockLoadFavoriteProductIDs(sampleProductIDs)

        // When
        let ids = await usecase.favoriteProductIDs()

        // Then
        XCTAssertEqual(sampleProductIDs, ids)
    }
}

private extension DefaultFavoriteProductsUseCaseTests {
    func mockLoadFavoriteProductIDs(_ ids: [Int64]) {
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFavoriteProductIDs(_, completion):
                completion(ids)
            default:
                break
            }
        }
    }
}

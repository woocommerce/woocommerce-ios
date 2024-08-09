import XCTest
import enum Yosemite.MediaAction
@testable import WooCommerce

final class WordPressMediaLibraryPickerDataSourceTests: XCTestCase {

    private let siteID: Int64 = 123
    private var stores: MockStoresManager!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        stores = nil
    }

    // MARK: Retrieve media using product ID

    func test_it_retrieves_media_using_product_id_as_nil_when_productID_is_not_provided() throws {
        // Given
        let sut = WordPressMediaLibraryPickerDataSource(siteID: siteID,
                                                        imagesOnly: true,
                                                        stores: stores)

        var receivedProductID: Int64?
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            switch action {
            case let .retrieveMediaLibrary(_, productID, _, _, _, onCompletion):
                receivedProductID = productID
                onCompletion(.success([.fake()]))
            default:
                break
            }
        }

        // When
        sut.sync(pageNumber: 1, pageSize: 25, reason: "", onCompletion: nil)

        // Then
        XCTAssertNil(receivedProductID)
    }

    func test_it_retrieves_media_using_product_id_when_productID_is_provided() throws {
        // Given
        let sut = WordPressMediaLibraryPickerDataSource(siteID: siteID,
                                                        productID: 321,
                                                        imagesOnly: true,
                                                        stores: stores)

        var receivedProductID: Int64?
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            switch action {
            case let .retrieveMediaLibrary(_, productID, _, _, _, onCompletion):
                receivedProductID = productID
                onCompletion(.success([.fake()]))
            default:
                break
            }
        }

        // When
        sut.sync(pageNumber: 1, pageSize: 25, reason: "", onCompletion: nil)

        // Then
        XCTAssertEqual(receivedProductID, 321)
    }
}

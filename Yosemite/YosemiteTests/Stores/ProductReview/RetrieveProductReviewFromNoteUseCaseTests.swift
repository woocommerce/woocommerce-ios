import XCTest

import Storage

@testable import Yosemite

final class RetrieveProductReviewFromNoteUseCaseTests: XCTestCase {

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var notificationsRemote: MockNotificationsRemote!
    private var productReviewsRemote: MockProductReviewsRemote!
    private var productsRemote: MockProductsRemote!

    /// The system being tested
    ///
    private var useCase: RetrieveProductReviewFromNoteUseCase!

    override func setUp() {
        super.setUp()

        storageManager = MockupStorageManager()

        notificationsRemote = MockNotificationsRemote()
        productReviewsRemote = MockProductReviewsRemote()
        productsRemote = MockProductsRemote()

        useCase = RetrieveProductReviewFromNoteUseCase(derivedStorage: storage,
                                                       notificationsRemote: notificationsRemote,
                                                       productReviewsRemote: productReviewsRemote,
                                                       productsRemote: productsRemote)
    }

    override func tearDown() {
        useCase = nil

        productsRemote = nil
        productReviewsRemote = nil
        notificationsRemote = nil

        storageManager = nil

        super.tearDown()
    }

    func testItFetchesAllEntitiesAndReturnsTheParcel() throws {
        // Given
        let note = TestData.note
        let productReview = TestData.productReview
        let product = TestData.product

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .success([note]))
        productReviewsRemote.whenLoadingProductReview(siteID: productReview.siteID,
                                                      reviewID: productReview.reviewID,
                                                      thenReturn: .success(productReview))
        productsRemote.whenLoadingProduct(siteID: product.siteID,
                                          productID: product.productID,
                                          thenReturn: .success(product))

        // When
        let result = try retrieve(noteID: note.noteID)

        // Then
        XCTAssert(result.isSuccess)

        let parcel = try XCTUnwrap(result.get())
        XCTAssertEqual(parcel.note.noteID, note.noteID)
        XCTAssertEqual(parcel.review, productReview)
        XCTAssertEqual(parcel.product, product)
    }
}

// MARK: - Utils

private extension RetrieveProductReviewFromNoteUseCaseTests {
    func retrieve(noteID: Int64) throws -> Result<ProductReviewFromNoteParcel, Error> {
        var result: Result<ProductReviewFromNoteParcel, Error>?

        waitForExpectation { exp in
            useCase.retrieve(noteID: noteID) { aResult in
                print(aResult)
                result = aResult
                exp.fulfill()
            }
        }

        return try XCTUnwrap(result)
    }
}

// MARK: - Test Data

private extension RetrieveProductReviewFromNoteUseCaseTests {
    enum TestData {
        static let siteID: Int64 = 398
        static let product = MockProduct().product(siteID: siteID, productID: 756_611)
        static let productReview = MockProductReview().make(siteID: siteID, reviewID: 1_981_157, productID: product.productID)
        static let note = MockNote().make(noteID: 9_981, metaSiteID: siteID, metaReviewID: productReview.reviewID)
    }
}

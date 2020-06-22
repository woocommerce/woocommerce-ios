import XCTest

import Storage
import enum Networking.NetworkError

@testable import Yosemite

private typealias ProductReviewFromNoteRetrieveError = RetrieveProductReviewFromNoteUseCase.ProductReviewFromNoteRetrieveError

/// Test cases for `RetrieveProductReviewFromNoteUseCase`.
///
final class RetrieveProductReviewFromNoteUseCaseTests: XCTestCase {

    private var notificationsRemote: MockNotificationsRemote!
    private var productReviewsRemote: MockProductReviewsRemote!
    private var productsRemote: MockProductsRemote!

    override func setUp() {
        super.setUp()

        notificationsRemote = MockNotificationsRemote()
        productReviewsRemote = MockProductReviewsRemote()
        productsRemote = MockProductsRemote()
    }

    override func tearDown() {
        productsRemote = nil
        productReviewsRemote = nil
        notificationsRemote = nil

        super.tearDown()
    }

    func testItFetchesAllEntitiesAndReturnsTheParcel() throws {
        // Given
        let storageManager = MockupStorageManager()
        let useCase = makeUseCase(storage: storageManager.viewStorage)
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
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isSuccess)

        let parcel = try XCTUnwrap(result.get())
        XCTAssertEqual(parcel.note.noteID, note.noteID)
        XCTAssertEqual(parcel.review, productReview)
        XCTAssertEqual(parcel.product, product)
    }

    func testWhenSuccessfulThenItSavesTheProductReviewToStorage() throws {
        // Given
        let storageManager = MockupStorageManager()
        let storage = storageManager.viewStorage

        let useCase = makeUseCase(storage: storage)

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

        XCTAssertEqual(storage.countObjects(ofType: StorageProductReview.self), 0)

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(storage.countObjects(ofType: StorageProductReview.self), 1)

        let reviewFromStorage = storage.loadProductReview(siteID: productReview.siteID, reviewID: productReview.reviewID)
        XCTAssertNotNil(reviewFromStorage)
    }

    /// Simulate a scenario where the StorageType is no longer available, which may happen
    /// if the owning `ProductReviewStore` is deallocated during user log out.
    ///
    func testWhenSuccessfulButStorageIsNoLongerAvailableThenItReturnsAFailure() throws {
        // Given
        var storageManager: StorageManagerType? = MockupStorageManager()

        let useCase = makeUseCase(storage: try XCTUnwrap(storageManager?.viewStorage))

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
        // Force deallocation of StorageManager and Storage.
        storageManager = nil

        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? ProductReviewFromNoteRetrieveError,
                       ProductReviewFromNoteRetrieveError.storageNoLongerAvailable)

        XCTAssertEqual(productsRemote.invocationCountOfLoadProduct, 0)
    }

    func testWhenNoteFetchFailsThenAllOtherFetchesAreAborted() throws {
        // Given
        let storageManager = MockupStorageManager()
        let useCase = makeUseCase(storage: storageManager.viewStorage)

        let note = TestData.note

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .failure(NetworkError.notFound))

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, NetworkError.notFound)

        XCTAssertEqual(notificationsRemote.invocationCountOfLoadNotes, 1)
        XCTAssertEqual(productReviewsRemote.invocationCountOfLoadProductReview, 0)
        XCTAssertEqual(productsRemote.invocationCountOfLoadProduct, 0)
    }

    func testWhenProductReviewFetchFailsThenAllOtherFetchesAreAborted() throws {
        // Given
        let storageManager = MockupStorageManager()
        let useCase = makeUseCase(storage: storageManager.viewStorage)

        let note = TestData.note
        let productReview = TestData.productReview

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .success([note]))
        productReviewsRemote.whenLoadingProductReview(siteID: productReview.siteID,
                                                      reviewID: productReview.reviewID,
                                                      thenReturn: .failure(NetworkError.timeout))

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, NetworkError.timeout)

        XCTAssertEqual(notificationsRemote.invocationCountOfLoadNotes, 1)
        XCTAssertEqual(productReviewsRemote.invocationCountOfLoadProductReview, 1)
        XCTAssertEqual(productsRemote.invocationCountOfLoadProduct, 0)
    }

    func testWhenNoteHasMissingMetaThenItReturnsAFailure() throws {
        // Given
        let storageManager = MockupStorageManager()
        let useCase = makeUseCase(storage: storageManager.viewStorage)

        // No `.comment` identifier. This can mean that we fetched the incorrect notification.
        let note = MockNote().make(noteID: 9_135, metaSiteID: TestData.siteID)

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .success([note]))

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? ProductReviewFromNoteRetrieveError,
                       ProductReviewFromNoteRetrieveError.reviewNotFound)

        XCTAssertEqual(notificationsRemote.invocationCountOfLoadNotes, 1)
        XCTAssertEqual(productReviewsRemote.invocationCountOfLoadProductReview, 0)
        XCTAssertEqual(productsRemote.invocationCountOfLoadProduct, 0)
    }
}

// MARK: - Utils

private extension RetrieveProductReviewFromNoteUseCaseTests {

    /// Create a UseCase using the mocks
    ///
    func makeUseCase(storage: StorageType) -> RetrieveProductReviewFromNoteUseCase {
        RetrieveProductReviewFromNoteUseCase(derivedStorage: storage,
                                             notificationsRemote: notificationsRemote,
                                             productReviewsRemote: productReviewsRemote,
                                             productsRemote: productsRemote)
    }

    /// Retrieve the Parcel using the given UseCase
    ///
    func retrieveAndWait(using useCase: RetrieveProductReviewFromNoteUseCase,
                         noteID: Int64) throws -> Result<ProductReviewFromNoteParcel, Error> {
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

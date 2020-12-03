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
    private var storageManager: MockStorageManager!

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()

        notificationsRemote = MockNotificationsRemote()
        productReviewsRemote = MockProductReviewsRemote()
        productsRemote = MockProductsRemote()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        productsRemote = nil
        productReviewsRemote = nil
        notificationsRemote = nil

        super.tearDown()
    }

    func test_it_fetches_all_entities_and_returns_the_Parcel() throws {
        // Given
        let useCase = makeUseCase()
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

    func test_it_uses_the_existing_Note_in_Storage_if_it_is_available() throws {
        // Given
        let useCase = makeUseCase()
        let note = TestData.note
        let productReview = TestData.productReview
        let product = TestData.product

        let storageNote = viewStorage.insertNewObject(ofType: StorageNote.self)
        storageNote.update(with: note)
        viewStorage.saveIfNeeded()

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
        XCTAssertEqual(notificationsRemote.invocationCountOfLoadNotes, 0)

        let parcel = try XCTUnwrap(result.get())
        XCTAssertEqual(parcel.note.noteID, note.noteID)
    }

    func test_it_uses_the_existing_Product_in_Storage_if_it_is_available() throws {
        // Given
        let useCase = makeUseCase()
        let note = TestData.note
        let productReview = TestData.productReview
        let product = TestData.product

        let storageProduct = viewStorage.insertNewObject(ofType: StorageProduct.self)
        storageProduct.update(with: product)
        viewStorage.saveIfNeeded()

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .success([note]))
        productReviewsRemote.whenLoadingProductReview(siteID: productReview.siteID,
                                                      reviewID: productReview.reviewID,
                                                      thenReturn: .success(productReview))

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(productsRemote.invocationCountOfLoadProduct, 0)

        let parcel = try XCTUnwrap(result.get())
        XCTAssertEqual(parcel.product, product)
    }

    func test_it_uses_the_existing_ProductReview_in_Storage_if_it_is_available() throws {
        // Given
        let useCase = makeUseCase()
        let note = TestData.note
        let productReview = TestData.productReview
        let product = TestData.product

        let storageProductReview = viewStorage.insertNewObject(ofType: StorageProductReview.self)
        storageProductReview.update(with: productReview)
        viewStorage.saveIfNeeded()

        notificationsRemote.whenLoadingNotes(noteIDs: [note.noteID], thenReturn: .success([note]))
        productsRemote.whenLoadingProduct(siteID: product.siteID,
                                          productID: product.productID,
                                          thenReturn: .success(product))


        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(productReviewsRemote.invocationCountOfLoadProductReview, 0)

        let parcel = try XCTUnwrap(result.get())
        XCTAssertEqual(parcel.review, productReview)
    }

    func test_when_successful_then_it_saves_the_ProductReview_to_Storage() throws {
        // Given
        let useCase = makeUseCase()

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

        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductReview.self), 0)

        // When
        let result = try retrieveAndWait(using: useCase, noteID: note.noteID)

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: StorageProductReview.self), 1)

        let reviewFromStorage = viewStorage.loadProductReview(siteID: productReview.siteID, reviewID: productReview.reviewID)
        XCTAssertNotNil(reviewFromStorage)
    }

    /// Simulate a scenario where the StorageType is no longer available, which may happen
    /// if the owning `ProductReviewStore` is deallocated during user log out.
    ///
    func test_when_successful_but_Storage_is_no_longer_available_then_it_returns_a_failure() throws {
        // Given
        let useCase = makeUseCase()

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

    func test_when_Note_fetch_fails_then_all_other_fetches_are_aborted() throws {
        // Given
        let useCase = makeUseCase()

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

    func test_when_ProductReview_fetch_fails_then_all_other_fetches_are_aborted() throws {
        // Given
        let useCase = makeUseCase()

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

    func test_when_Note_has_missing_meta_then_it_returns_a_failure() throws {
        // Given
        let useCase = makeUseCase()

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
    func makeUseCase() -> RetrieveProductReviewFromNoteUseCase {
        RetrieveProductReviewFromNoteUseCase(derivedStorage: viewStorage,
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

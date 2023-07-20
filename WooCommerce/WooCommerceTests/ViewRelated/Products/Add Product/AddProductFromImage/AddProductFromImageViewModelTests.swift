import TestKit
import XCTest
import Yosemite

@testable import WooCommerce

@MainActor
final class AddProductFromImageViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .makeForTesting())
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        stores = nil
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_initial_name_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    // MARK: - `addImage`

    func test_imageState_is_reverted_to_empty_when_addImage_returns_nil() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in
            nil
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then
        waitUntil {
            viewModel.imageState == .empty
        }
    }

    func test_imageState_is_reverted_to_success_when_addImage_returns_image_then_nil() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        var imageToReturn: MediaPickerImage? = image
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, onAddImage: { _ in
            imageToReturn
        })
        XCTAssertEqual(viewModel.imageState, .empty)

        // When adding an image returns an image
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState becomes success
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // When adding an image returns nil
        imageToReturn = nil
        viewModel.addImage(from: .siteMediaLibrary)
        XCTAssertEqual(viewModel.imageState, .loading)

        // Then imageState stays success
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }

    func test_imageState_success_generates_details_with_scanned_texts() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc", language: "en")))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        waitUntil {
            viewModel.isGeneratingDetails == false
        }
        XCTAssertEqual(viewModel.name, "Name")
        XCTAssertEqual(viewModel.description, "Desc")
    }

    func test_generatesProductDetails_failure_sets_errorMessage_and_resets_errorMessage_after_regenerating() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .failure(SampleError.first))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        waitUntil {
            viewModel.isGeneratingDetails == false
        }
        XCTAssertNotNil(viewModel.errorMessage)

        // When regenerating product details with success
        mockGenerateProductDetails(result: .success(.init(name: "", description: "", language: "")))
        viewModel.generateProductDetails()

        // Then `errorMessage` is reset
        waitUntil {
            viewModel.errorMessage == nil
        }
    }

    func test_generateProductDetails_without_scanned_text_does_not_dispatch_product_action() {
        // Given
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     onAddImage: { _ in nil })

        // When
        viewModel.generateProductDetails()
    }

    func test_generateProductDetails_filters_empty_scanned_texts() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["", "Product", ""]))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDetails(_, scannedTexts, _) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            // Then
            XCTAssertEqual(scannedTexts, ["Product"])
        }

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }

    // MARK: Analytics

    func test_displayed_event_is_tracked_when_the_view_model_is_init() throws {
        // When
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     analytics: analytics,
                                                     onAddImage: { _ in nil })

        // Then
        let eventName = "add_product_from_image_displayed"
        XCTAssertEqual(analyticsProvider.receivedEvents, [eventName])
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
    }

    func test_image_text_scan_success_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in image })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        let eventName = "add_product_from_image_scan_completed"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
        assertEqual(1, eventProperties["scanned_text_count"] as? Int)
    }

    func test_image_text_scan_failure_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let error = NSError(domain: "test", code: 10000)
        let imageTextScanner = MockImageTextScanner(result: .failure(error))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in image })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }

        // Then
        let eventName = "add_product_from_image_scan_failed"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
        assertEqual("test", eventProperties["error_domain"] as? String)
        assertEqual("10000", eventProperties["error_code"] as? String)
    }

    func test_product_detail_generation_success_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc", language: "en")))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }
        waitUntil {
            viewModel.isGeneratingDetails == false
        }

        // Then
        let eventName = "add_product_from_image_details_generated"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
        assertEqual("en", eventProperties["language"] as? String)
        assertEqual(1, eventProperties["selected_text_count"] as? Int)
    }

    func test_product_detail_generation_failure_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        let error = NSError(domain: "Server", code: 500)
        mockGenerateProductDetails(result: .failure(error))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in
            image
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }
        waitUntil {
            viewModel.isGeneratingDetails == false
        }

        // Then
        let eventName = "add_product_from_image_detail_generation_failed"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
        assertEqual("Server", eventProperties["error_domain"] as? String)
        assertEqual("500", eventProperties["error_code"] as? String)
    }

    func test_trackContinueButtonTapped_tracks_correct_event_and_properties() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     analytics: analytics,
                                                     onAddImage: { _ in nil })

        // When
        viewModel.trackContinueButtonTapped()

        // Then
        let eventName = "add_product_from_image_continue_button_tapped"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("products_tab", eventProperties["source"] as? String)
        assertEqual(true, eventProperties["is_name_empty"] as? Bool)
        assertEqual(true, eventProperties["is_description_empty"] as? Bool)
        assertEqual(false, eventProperties["has_scanned_text"] as? Bool)
        assertEqual(false, eventProperties["has_generated_details"] as? Bool)
    }

    // MARK: `regenerateButtonEnabled`

    func test_regenerateButtonEnabled_returns_true_if_there_is_at_least_one_non_empty_and_selected_scanned_text() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     onAddImage: { _ in nil })

        // When
        viewModel.scannedTexts = [.init(text: "test", isSelected: true),
                                  .init(text: "", isSelected: false)]

        // Then
        XCTAssertTrue(viewModel.regenerateButtonEnabled)
    }

    func test_regenerateButtonEnabled_returns_false_if_all_scanned_texts_are_either_empty_or_unselected() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     onAddImage: { _ in nil })

        // When
        viewModel.scannedTexts = [.init(text: "test", isSelected: false),
                                  .init(text: "", isSelected: false)]

        // Then
        XCTAssertFalse(viewModel.regenerateButtonEnabled)
    }
}

private extension AddProductFromImageViewModelTests {
    func mockGenerateProductDetails(result: Result<ProductDetailsFromScannedTexts, Error>) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            guard case let .generateProductDetails(_, _, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            completion(result)
        }
    }
}

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
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, productName: nil, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.name, "")
    }

    func test_initial_description_is_empty() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, productName: nil, onAddImage: { _ in nil })

        // Then
        XCTAssertEqual(viewModel.description, "")
    }

    // MARK: - `addImage`

    func test_imageState_is_reverted_to_empty_when_addImage_returns_nil() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, productName: nil, onAddImage: { _ in
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
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, productName: nil, onAddImage: { _ in
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
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc")))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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

    func test_generatesProductDetails_failure_sets_textGenerationErrorMessage_and_resets_textGenerationErrorMessage_after_regenerating() {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .failure(SampleError.first))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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
        XCTAssertNotNil(viewModel.textGenerationErrorMessage)

        // When regenerating product details with success
        mockGenerateProductDetails(result: .success(.init(name: "", description: "")))
        viewModel.generateProductDetails()

        // Then `textGenerationErrorMessage` is reset
        waitUntil {
            viewModel.textGenerationErrorMessage == nil
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
                                                     productName: nil,
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
                                                     productName: nil,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            image
        })

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDetails(_, _, scannedTexts, _, _):
                // Then
                XCTAssertEqual(scannedTexts, ["Product"])
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
            default:
                return XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(image)
        }
    }

    // MARK: New Image selection resets details from previous image

    func test_details_from_previous_scan_are_reset_when_new_image_selected() throws {
        // Given
        let firstImage = MediaPickerImage(image: UIImage.emailImage,
                                          source: .media(media: .fake()))
        let secondImage = MediaPickerImage(image: UIImage.calendar,
                                           source: .media(media: .fake()))
        var imageToReturn: MediaPickerImage? = firstImage
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .success(.init(name: "Name",
                                                          description: "Desc")))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     productName: nil,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in imageToReturn })
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(firstImage)
        }
        waitUntil {
            viewModel.isGeneratingDetails == false
        }

        // Loaded details from previous image
        XCTAssertTrue(viewModel.scannedTexts.isNotEmpty)
        XCTAssertTrue(viewModel.name.isNotEmpty)
        XCTAssertTrue(viewModel.description.isNotEmpty)

        // When
        imageTextScanner.result = .success([])
        imageToReturn = secondImage

        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(secondImage)
        }

        // Then
        XCTAssertTrue(viewModel.scannedTexts.isEmpty)
        XCTAssertTrue(viewModel.name.isEmpty)
        XCTAssertTrue(viewModel.description.isEmpty)
    }

    // MARK: `textDetectionErrorMessage`

    func test_textDetectionErrorMessage_is_nil_initially() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6, source: .productsTab, productName: nil, onAddImage: { _ in
            nil
        })

        // Then
        XCTAssertNil(viewModel.textDetectionErrorMessage)
    }

    func test_textDetectionErrorMessage_has_correct_string_value_when_no_text_is_detected() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success([]))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     productName: nil,
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
        XCTAssertEqual(viewModel.textDetectionErrorMessage,
                       "No text detected. Please select another packaging photo or enter product details manually.")
    }

    func test_textDetectionErrorMessage_has_correct_string_value_when_text_detection_fails() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let error = NSError(domain: "test", code: 10000)
        let imageTextScanner = MockImageTextScanner(result: .failure(error))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     productName: nil,
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
        XCTAssertEqual(viewModel.textDetectionErrorMessage,
                       "An error occurred while scanning the photo. Please select another packaging photo or enter product details manually.")
    }

    func test_textDetectionErrorMessage_is_reset_when_image_with_text_is_loaded_again() throws {
        // Given
        let firstImage = MediaPickerImage(image: UIImage.emailImage,
                                          source: .media(media: .fake()))
        let secondImage = MediaPickerImage(image: UIImage.calendar,
                                           source: .media(media: .fake()))

        var imageToReturn: MediaPickerImage? = firstImage

        let imageTextScanner = MockImageTextScanner(result: .success([]))
        let viewModel = AddProductFromImageViewModel(siteID: 123,
                                                     source: .productsTab,
                                                     productName: nil,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     analytics: analytics,
                                                     onAddImage: { _ in imageToReturn })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(firstImage)
        }

        // Then
        XCTAssertEqual(viewModel.textDetectionErrorMessage, "No text detected. Please select another packaging photo or enter product details manually.")

        // When
        imageTextScanner.result = .success(["test"])
        imageToReturn = secondImage

        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(secondImage)
        }

        // Then
        XCTAssertNil(viewModel.textDetectionErrorMessage)
    }

    // MARK: Analytics

    func test_displayed_event_is_tracked_when_the_view_model_is_init() throws {
        // When
        _ = AddProductFromImageViewModel(siteID: 123,
                                         source: .productsTab,
                                         productName: nil,
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
                                                     productName: nil,
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
                                                     productName: nil,
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
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc")))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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
                                                     productName: nil,
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

    func test_identify_language_success_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let sampleLanguage = "ta"
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc")),
                                   identifyLanguageResult: .success(sampleLanguage))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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
        let eventName = "ai_identify_language_success"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("product_details_from_scanned_texts", eventProperties["source"] as? String)
        assertEqual(sampleLanguage, eventProperties["language"] as? String)
    }

    func test_identify_language_failure_is_tracked() throws {
        // Given
        let image = MediaPickerImage(image: .init(), source: .media(media: .fake()))
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        let error = NSError(domain: "Server", code: 500)
        mockGenerateProductDetails(result: .success(.init(name: "Name", description: "Desc")),
                                   identifyLanguageResult: .failure(error))
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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
        let eventName = "ai_identify_language_failed"
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(eventName))
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]

        assertEqual("product_details_from_scanned_texts", eventProperties["source"] as? String)
        assertEqual("Server", eventProperties["error_domain"] as? String)
        assertEqual("500", eventProperties["error_code"] as? String)
    }

    func test_trackContinueButtonTapped_tracks_correct_event_and_properties() throws {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
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

    func test_regenerateButtonEnabled_is_updated_correctly() {
        // Given
        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil, onAddImage: { _ in nil })
        let firstText: AddProductFromImageViewModel.ScannedTextViewModel = .init(text: "peach tea", isSelected: true)
        let secondText: AddProductFromImageViewModel.ScannedTextViewModel = .init(text: "sweet", isSelected: true)

        // When
        viewModel.scannedTexts = [firstText, secondText]

        // Then
        XCTAssertTrue(viewModel.regenerateButtonEnabled)

        // When: clear and unselect texts
        firstText.text = ""
        secondText.isSelected = false

        // Then
        XCTAssertFalse(viewModel.regenerateButtonEnabled)

        // When: all texts are updated
        viewModel.scannedTexts = [.init(text: "ramen", isSelected: true),
                                  .init(text: "spicy", isSelected: true)]

        // Then
        XCTAssertTrue(viewModel.regenerateButtonEnabled)
    }

    // MARK: - Language identification request

    func test_identify_language_request_is_sent_only_when_image_changes() {
        // Given
        let firstImage = MediaPickerImage(image: UIImage.emailImage,
                                          source: .media(media: .fake()))
        let secondImage = MediaPickerImage(image: UIImage.calendar,
                                           source: .media(media: .fake()))
        var imageToReturn: MediaPickerImage? = firstImage
        let imageTextScanner = MockImageTextScanner(result: .success(["test"]))
        var identifyLanguageRequestCounter = 0

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDetails(_, _, _, _, completion):
                completion(.success(.init(name: "Name", description: "Desc")))
            case let .identifyLanguage(_, _, _, completion):
                completion(.success("en"))
                identifyLanguageRequestCounter += 1
            default:
                return XCTFail("Unexpected action: \(action)")
            }
        }

        let viewModel = AddProductFromImageViewModel(siteID: 6,
                                                     source: .productsTab,
                                                     productName: nil,
                                                     stores: stores,
                                                     imageTextScanner: imageTextScanner,
                                                     onAddImage: { _ in
            imageToReturn
        })

        // When
        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(firstImage)
        }

        waitUntil {
            viewModel.isGeneratingDetails == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 1)

        // When
        viewModel.generateProductDetails()

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 1)

        // When
        imageTextScanner.result = .success(["test"])
        imageToReturn = secondImage

        viewModel.addImage(from: .siteMediaLibrary)
        waitUntil {
            viewModel.imageState == .success(secondImage)
        }

        waitUntil {
            viewModel.isGeneratingDetails == false
        }

        // Then
        XCTAssertEqual(identifyLanguageRequestCounter, 2)
    }
}

private extension AddProductFromImageViewModelTests {
    func mockGenerateProductDetails(result: Result<ProductDetailsFromScannedTexts, Error>,
                                    identifyLanguageResult: Result<String, Error> = .success("en")) {
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            switch action {
            case let .generateProductDetails(_, _, _, _, completion):
                completion(result)
            case let .identifyLanguage(_, _, _, completion):
                completion(identifyLanguageResult)
            default:
                return XCTFail("Unexpected action: \(action)")
            }
        }
    }
}

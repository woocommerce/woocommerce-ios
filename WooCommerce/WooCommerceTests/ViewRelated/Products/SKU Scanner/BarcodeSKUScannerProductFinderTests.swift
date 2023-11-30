import Foundation
import XCTest
import Yosemite
@testable import WooCommerce

final class BarcodeSKUScannerItemFinderTests: XCTestCase {
    private var sut: BarcodeSKUScannerItemFinder!
    private var stores: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)

        sut = BarcodeSKUScannerItemFinder(stores: stores, analytics: analytics)

    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        stores = nil
        storageManager = nil
        analyticsProvider = nil
        analytics = nil
    }

    func test_findProduct_when_there_is_an_error_then_passes_and_tracks_it() async {
        // Given
        let source = WooAnalyticsEvent.BarcodeScanning.Source.orderCreation
        let productNotFoundError = ProductLoadError.notFound
        let symbology = BarcodeSymbology.aztec
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                onCompletion(.failure(productNotFoundError))
            default:
                XCTFail("Expected failure, got success")
            }
        })

        let scannedBarcode = ScannedBarcode(payloadStringValue: "123456", symbology: symbology)
        var retrievedError: Error?

        do {
            _ = try await sut.searchBySKU(from: scannedBarcode, siteID: 1, source: source)
        } catch {
            retrievedError = error
        }

        XCTAssertEqual(retrievedError as? ProductLoadError, productNotFoundError)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.orderProductSearchViaSKUFailure.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["source"] as? String, source.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["barcode_format"] as? String, symbology.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["reason"] as? String, "Product not found")
    }

    func test_findProduct_when_sku_matches_barcode_then_returns_product() async {
        // Given
        let source = WooAnalyticsEvent.BarcodeScanning.Source.orderList
        let returningProduct = Product.fake()
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                onCompletion(.success(.product(returningProduct)))
            default:
                break
            }
        })

        // When
        let scannedBarcode = ScannedBarcode(payloadStringValue: "123456", symbology: .aztec)
        let result = try? await sut.searchBySKU(from: scannedBarcode, siteID: 1, source: source)

        guard case let .product(retrievedProduct) = result else {
            return XCTFail("It didn't provide a product as expected")
        }

        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
        XCTAssertEqual(analyticsProvider.receivedEvents.first, WooAnalyticsStat.orderProductSearchViaSKUSuccess.rawValue)
        XCTAssertEqual(analyticsProvider.receivedProperties.first?["source"] as? String, source.rawValue)
    }

    func test_findProduct_when_barcode_has_check_digit_and_right_symbology_then_it_tries_without_it_and_returns_product() async {

        for symbology in [BarcodeSymbology.ean13, BarcodeSymbology.upce] {
            await assertTriesWithoutCheckDigit(for: symbology)
        }
    }

    func test_findProduct_when_barcode_is_ean13_and_has_country_code_retries_without_it_and_without_check_digit_and_returns_product() async {
        let returningProduct = Product.fake()
        let productSKU = "72527273070"
        let countryCode = "0"
        let checkDigit = "6"
        let scannedBarcode = ScannedBarcode(payloadStringValue: countryCode + productSKU + checkDigit, symbology: .ean13)

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .retrieveFirstPurchasableItemMatchFromSKU(_, givenSKU, onCompletion):
                if givenSKU == productSKU {
                    onCompletion(.success(.product(returningProduct)))
                } else {
                    onCompletion(.failure(ProductLoadError.notFound))
                }
            default:
                break
            }
        })

        // When
        let result = try? await sut.searchBySKU(from: scannedBarcode, siteID: 1, source: .orderCreation)

        guard case let .product(retrievedProduct) = result else {
            return XCTFail("It didn't provide a product as expected")
        }


        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
    }

    private func assertTriesWithoutCheckDigit(for symbology: BarcodeSymbology) async {
        let returningProduct = Product.fake()
        let productSKU = "97802013796"
        let checkDigit = "3"
        let scannedBarcode = ScannedBarcode(payloadStringValue: productSKU + checkDigit, symbology: symbology)

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .retrieveFirstPurchasableItemMatchFromSKU(_, givenSKU, onCompletion):
                if givenSKU == productSKU {
                    onCompletion(.success(.product(returningProduct)))
                } else {
                    onCompletion(.failure(ProductLoadError.notFound))
                }
            default:
                break
            }
        })

        // When
        let result = try? await sut.searchBySKU(from: scannedBarcode, siteID: 1, source: .orderCreation)

        guard case let .product(retrievedProduct) = result else {
            return XCTFail("It didn't provide a product as expected")
        }


        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
    }
}

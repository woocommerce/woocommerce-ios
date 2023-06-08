import Foundation
import XCTest
import Yosemite
@testable import WooCommerce

final class BarcodeSKUScannerProductFinderTests: XCTestCase {
    private var sut: BarcodeSKUScannerProductFinder!
    var stores: MockStoresManager!
    var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        storageManager = MockStorageManager()

        sut = BarcodeSKUScannerProductFinder(stores: stores)

    }

    override func tearDown() {
        super.tearDown()

        sut = nil
        stores = nil
        storageManager = nil
    }

    func test_findProduct_when_there_is_an_error_then_passes_it() async {
        // Given
        let testError = TestError.anError
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstProductMatchFromSKU(_, _, let onCompletion):
                onCompletion(.failure(testError))
            default:
                XCTFail("Expected failure, got success")
            }
        })

        let scannedBarcode = ScannedBarcode(payloadStringValue: "123456", symbology: .aztec)
        var retrievedError: Error?

        do {
            _ = try await sut.findProduct(from: scannedBarcode, siteID: 1)
        } catch {
            retrievedError = error
        }

        XCTAssertEqual(retrievedError as? TestError, testError)
    }

    func test_findProduct_when_sku_matches_barcode_then_returns_product() async {
        // Given
        let returningProduct = Product.fake()
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstProductMatchFromSKU(_, _, let onCompletion):
                onCompletion(.success(returningProduct))
            default:
                break
            }
        })

        // When
        let scannedBarcode = ScannedBarcode(payloadStringValue: "123456", symbology: .aztec)
        let retrievedProduct = try? await sut.findProduct(from: scannedBarcode, siteID: 1)

        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
    }

    func test_findProduct_when_barcode_has_check_digit_and_right_symbology_then_it_tries_without_it_and_returns_product() async {

        for symbology in [BarcodeSymbology.ean13, BarcodeSymbology.upce] {
            await assertTriesWithoutCheckDigit(for: symbology)
        }
    }

    func test_findProduct_when_barcode_is_ean13_and_has_country_code_retries_without_it_and_without_check_digit_and_returns_product() async {
        let returningProduct = Product.fake()
        let productSKU = "72527273070"
        let scannedBarcode = ScannedBarcode(payloadStringValue: "0" + productSKU + "6", symbology: .ean13)

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .retrieveFirstProductMatchFromSKU(_, givenSKU, onCompletion):
                if givenSKU == productSKU {
                    onCompletion(.success(returningProduct))
                } else {
                    onCompletion(.failure(ProductLoadError.notFound))
                }
            default:
                break
            }
        })

        // When
        let retrievedProduct = try? await sut.findProduct(from: scannedBarcode, siteID: 1)

        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
    }

    func assertTriesWithoutCheckDigit(for symbology: BarcodeSymbology) async {
        let returningProduct = Product.fake()
        let productSKU = "97802013796"
        let scannedBarcode = ScannedBarcode(payloadStringValue: productSKU + "3", symbology: symbology)

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case let .retrieveFirstProductMatchFromSKU(_, givenSKU, onCompletion):
                if givenSKU == productSKU {
                    onCompletion(.success(returningProduct))
                } else {
                    onCompletion(.failure(ProductLoadError.notFound))
                }
            default:
                break
            }
        })

        // When
        let retrievedProduct = try? await sut.findProduct(from: scannedBarcode, siteID: 1)

        // Then
        XCTAssertEqual(retrievedProduct, returningProduct)
    }
}

private enum TestError: Error {
    case anError
}

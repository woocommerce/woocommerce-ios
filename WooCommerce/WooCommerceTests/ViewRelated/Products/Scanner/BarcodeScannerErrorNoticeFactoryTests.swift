import Foundation
import XCTest
import Yosemite
@testable import WooCommerce

final class BarcodeScannerErrorNoticeFactoryTests: XCTestCase {
    let barcode = ScannedBarcode(payloadStringValue: "test-sku", symbology: .ean13)
    let noticeTitle = NSLocalizedString("Cannot add Product to Order.", comment: "")

    func test_notice_when_a_generic_error_is_passed_then_returns_generic_notice() {
        let error = NSError(domain: "disconnect", code: 134)
        let result = BarcodeScannerErrorNoticeFactory.notice(for: error, code: barcode, actionHandler: {})

        XCTAssertEqual(result.title, NSLocalizedString("Cannot add Product to Order.", comment: ""))
    }

    func test_notice_when_a_product_not_found_error_is_passed_then_returns_right_notice() {
        let result = BarcodeScannerErrorNoticeFactory.notice(for: ProductLoadError.notFound, code: barcode, actionHandler: {})

        XCTAssertEqual(result.title, noticeTitle)
        XCTAssertEqual(result.message, NSLocalizedString("Product with Identifier \"\(barcode.payloadStringValue)\" not found.", comment: ""))
    }

    func test_notice_when_a_product_not_purchasable_error_is_passed_then_returns_right_notice() {
        let result = BarcodeScannerErrorNoticeFactory.notice(for: ProductLoadError.notPurchasable, code: barcode, actionHandler: {})

        XCTAssertEqual(result.title, noticeTitle)
        XCTAssertEqual(result.message, NSLocalizedString("Product with Identifier \"\(barcode.payloadStringValue)\" is not purchasable.", comment: ""))
    }

    func test_notice_passes_right_action_handler() {
        var actionHandlerIsCalled = false
        let result = BarcodeScannerErrorNoticeFactory.notice(for: ProductLoadError.notPurchasable, code: barcode, actionHandler: {
            actionHandlerIsCalled = true
        })

        result.actionHandler?()

        XCTAssertTrue(actionHandlerIsCalled)
    }
}

import XCTest
import SwiftUI

@testable import WooCommerce

final class PointOfSaleAssetsTests: XCTestCase {
    func test_posNewTransactionImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.newTransactionImageName))
    }

    func test_posPaymentSuccessfulImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.paymentSuccessfulImageName))
    }

    func test_posProcessingPaymentImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.processingPaymentImageName))
    }

    func test_posReadyForPaymentImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.readyForPaymentImageName))
    }

    func test_posCartBackImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.cartBackImageName))
    }

    func test_posExitImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.exitImageName))
    }

    func test_posGetSupportImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.getSupportImageName))
    }

    func test_posRemoveCartItemImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.removeCartItemImageName))
    }

    func test_posDismissProductsBannerImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.dismissProductsBannerImageName))
    }
}

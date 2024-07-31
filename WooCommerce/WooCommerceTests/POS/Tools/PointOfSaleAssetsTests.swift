import XCTest
import SwiftUI

@testable import WooCommerce

final class PointOfSaleAssetsTests: XCTestCase {
    func test_posNewTransactionImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.newTransaction.imageName))
    }

    func test_posPaymentSuccessfulImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.paymentSuccessful.imageName))
    }

    func test_posProcessingPaymentImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.processingPayment.imageName))
    }

    func test_posReadyForPaymentImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.readyForPayment.imageName))
    }

    func test_posCartBackImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.cartBack.imageName))
    }

    func test_posExitImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.exit.imageName))
    }

    func test_posGetSupportImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.getSupport.imageName))
    }

    func test_posRemoveCartItemImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.removeCartItem.imageName))
    }

    func test_posDismissProductsBannerImage_is_not_nil() {
        XCTAssertNotNil(Image(PointOfSaleAssets.dismissProductsBanner.imageName))
    }
}

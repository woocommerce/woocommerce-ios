import XCTest
@testable import WooCommerce
import Yosemite
import TestKit

/// Test cases for `ProductSettingsRows`.
///
final class ProductSettingsRowsTests: XCTestCase {

    private var originalSettings: ProductSettings?

    typealias AlertHandler = @convention(block) (UIAlertAction) -> Void

    override func setUp() {
        super.setUp()

        // Given
        originalSettings = ProductSettings(productType: .simple,
                                           status: .draft,
                                           featured: false,
                                           password: nil,
                                           catalogVisibility: .catalog,
                                           virtual: false,
                                           reviewsAllowed: false,
                                           slug: "",
                                           purchaseNote: nil,
                                           menuOrder: 0,
                                           downloadable: false)
    }

    override func tearDown() {
        super.tearDown()
    }

    func test_virtual_product_row_changed_when_updated() throws {
        let settings = try XCTUnwrap(originalSettings)

        // Given
        let virtualProduct = ProductSettingsRows.VirtualProduct(settings)

        let cell = SwitchTableViewCell()
        virtualProduct.configure(cell: cell, sourceViewController: UIViewController())

        // When
        cell.onChange?(true)

        // Then
        XCTAssertEqual(settings.virtual, true)
    }

    func test_reviewsAllowed_row_changed_when_updated() throws {
        let settings = try XCTUnwrap(originalSettings)

        // Given
        let reviewsAllowed = ProductSettingsRows.ReviewsAllowed(settings)

        let cell = SwitchTableViewCell()
        reviewsAllowed.configure(cell: cell, sourceViewController: UIViewController())

        // When
        cell.onChange?(true)

        // Then
        XCTAssertEqual(settings.reviewsAllowed, true)
    }

    func test_downloadable_product_row_changed_when_enabled() throws {
        let settings = try XCTUnwrap(originalSettings)

        // Given
        let downloadableProduct = ProductSettingsRows.DownloadableProduct(settings)

        let cell = SwitchTableViewCell()
        downloadableProduct.configure(cell: cell, sourceViewController: UIViewController())

        // When
        cell.onChange?(true)

        // Then
        XCTAssertEqual(settings.downloadable, true)
    }

    func test_downloadable_product_row_alert_when_disabled() throws {
        let sourceViewController = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = sourceViewController

        let settings = try XCTUnwrap(originalSettings)

        // Given
        let downloadableProduct = ProductSettingsRows.DownloadableProduct(settings)

        let cell = SwitchTableViewCell()
        downloadableProduct.configure(cell: cell, sourceViewController: sourceViewController)

        // Whenˇ
        cell.onChange?(false)

        // Then
        assertThat(sourceViewController.presentedViewController, isAnInstanceOf: UIAlertController.self)
        let alertController = try XCTUnwrap(sourceViewController.presentedViewController as? UIAlertController)
        XCTAssertEqual(alertController.actions.count, 2)
    }

    func test_downloadable_product_row_changed_when_alert_confirmed() throws {
        let sourceViewController = UIViewController()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        window.rootViewController = sourceViewController

        let settings = try XCTUnwrap(originalSettings)

        // Given
        let downloadableProduct = ProductSettingsRows.DownloadableProduct(settings)

        let cell = SwitchTableViewCell()
        downloadableProduct.configure(cell: cell, sourceViewController: sourceViewController)

        // Whenˇ
        cell.onChange?(false)
        let alertController = try XCTUnwrap(sourceViewController.presentedViewController as? UIAlertController)
        alertController.tapButton(atIndex: 0)

        // Then
        XCTAssertEqual(settings.downloadable, false)
    }
}

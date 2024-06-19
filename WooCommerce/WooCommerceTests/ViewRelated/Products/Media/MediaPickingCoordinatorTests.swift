import XCTest
@testable import WooCommerce

final class MediaPickingCoordinatorTests: XCTestCase {

    private let siteID: Int64 = 123
    private let sourceViewController = UIViewController()
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil
        super.tearDown()
    }

    func test_showMediaPicker_tracks_correct_event_and_properties() throws {
        // Given
        let coordinator = MediaPickingCoordinator(siteID: siteID,
                                                  imagesOnly: true,
                                                  allowsMultipleSelections: true,
                                                  flow: .productFromImageForm,
                                                  analytics: analytics,
                                                  onCameraCaptureCompletion: { _, _ in },
                                                  onDeviceMediaLibraryPickerCompletion: { _ in },
                                                  onWPMediaPickerCompletion: { _ in })

        // When
        coordinator.showMediaPicker(source: .photoLibrary, from: sourceViewController)

        // Then
        let eventName = "product_image_settings_add_images_source_tapped"
        XCTAssertEqual(analyticsProvider.receivedEvents, [eventName])
        let eventIndex = try XCTUnwrap(analyticsProvider.receivedEvents.firstIndex(where: { $0 == eventName}))
        let eventProperties = analyticsProvider.receivedProperties[eventIndex]
        assertEqual("device", eventProperties["source"] as? String)
        assertEqual(("product_from_image_form"), eventProperties["flow"] as? String)
    }

}

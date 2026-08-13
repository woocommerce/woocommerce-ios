import Testing
import UIKit
@testable import WooCommerce

struct TracksProviderPointOfSalePropertiesTests {

    private let sut = TracksProvider()
    private let deviceTypeKey = "device_type"
    private let entryPointKey = "entry_point"

    @Test func test_addPointOfSaleProperties_adds_device_type_and_entry_point() {
        // When
        let result = sut.addPointOfSaleProperties(to: [:], deviceType: "tablet", entryPoint: .posTab)

        // Then
        #expect(result[deviceTypeKey] as? String == "tablet")
        #expect(result[entryPointKey] as? String == "pos_tab")
    }

    @Test func test_addPointOfSaleProperties_when_entry_point_is_unknown_then_only_device_type_is_added() {
        // When
        let result = sut.addPointOfSaleProperties(to: nil, deviceType: "phone", entryPoint: nil)

        // Then
        #expect(result.count == 1)
        #expect(result[deviceTypeKey] as? String == "phone")
    }

    @Test func test_addPointOfSaleProperties_preserves_other_properties() {
        // Given
        let existingProperties: [AnyHashable: Any] = ["sync_strategy": "local"]

        // When
        let result = sut.addPointOfSaleProperties(to: existingProperties, deviceType: "tablet", entryPoint: .autoReopen)

        // Then
        #expect(result["sync_strategy"] as? String == "local")
        #expect(result[entryPointKey] as? String == "auto_reopen")
    }

    @Test func test_given_pos_was_entered_when_pos_is_exited_then_events_no_longer_carry_entry_point() {
        // Given
        TracksProvider.setPOSEntryPoint(.posTab)
        TracksProvider.setPOSMode(true)

        // When
        TracksProvider.setPOSMode(false)

        // Then
        let result = sut.addPointOfSaleProperties(to: [:],
                                                  deviceType: "tablet",
                                                  entryPoint: TracksProvider.posEntryPoint)
        #expect(result[entryPointKey] == nil)
        #expect(result[deviceTypeKey] as? String == "tablet")
    }

    @Test func test_deviceTypeForAnalytics_maps_each_idiom_to_its_own_value() {
        // Then
        #expect(UIUserInterfaceIdiom.phone.deviceTypeForAnalytics == "phone")
        #expect(UIUserInterfaceIdiom.pad.deviceTypeForAnalytics == "tablet")
        #expect(UIUserInterfaceIdiom.mac.deviceTypeForAnalytics == "mac")
        #expect(UIUserInterfaceIdiom.vision.deviceTypeForAnalytics == "vision")
        #expect(UIUserInterfaceIdiom.tv.deviceTypeForAnalytics == "tv")
        #expect(UIUserInterfaceIdiom.carPlay.deviceTypeForAnalytics == "car_play")
        #expect(UIUserInterfaceIdiom.unspecified.deviceTypeForAnalytics == "unspecified")
    }
}

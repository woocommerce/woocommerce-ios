import Testing
import UIKit
@testable import WooCommerce

struct TracksProviderPointOfSalePropertiesTests {

    private let sut = TracksProvider()
    private let deviceTypeKey = "device_type"
    private let entryPointKey = "entry_point"

    @Test func addPointOfSaleProperties_when_entry_point_is_known_then_adds_device_type_and_entry_point() {
        // When
        let result = sut.addPointOfSaleProperties(to: [:], deviceType: "tablet", entryPoint: .posTab)

        // Then
        #expect(result[deviceTypeKey] as? String == "tablet")
        #expect(result[entryPointKey] as? String == "pos_tab")
    }

    @Test func addPointOfSaleProperties_when_entry_point_is_unknown_then_only_device_type_is_added() {
        // When
        let result = sut.addPointOfSaleProperties(to: nil, deviceType: "phone", entryPoint: nil)

        // Then
        #expect(result.count == 1)
        #expect(result[deviceTypeKey] as? String == "phone")
    }

    @Test func addPointOfSaleProperties_when_properties_already_exist_then_they_are_preserved() {
        // Given
        let existingProperties: [AnyHashable: Any] = ["sync_strategy": "local"]

        // When
        let result = sut.addPointOfSaleProperties(to: existingProperties, deviceType: "tablet", entryPoint: .autoReopen)

        // Then
        #expect(result["sync_strategy"] as? String == "local")
        #expect(result[entryPointKey] as? String == "auto_reopen")
    }

    @Test func deviceTypeForAnalytics_when_mapping_each_idiom_then_returns_its_own_value() {
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

import Testing
import UIKit
@testable import WooCommerce

@MainActor
struct QRLoginDeviceInfoProviderTests {

    @Test func device_model_when_read_then_is_the_generic_device_model_not_the_hardware_identifier() {
        // When
        let model = DefaultQRLoginDeviceInfoProvider().device.model

        // Then
        #expect(model == UIDevice.current.model)
        #expect(model.contains(",") == false)
    }
}

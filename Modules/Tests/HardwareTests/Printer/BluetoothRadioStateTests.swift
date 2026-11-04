import CoreBluetooth
import Testing
@testable import Hardware

struct BluetoothRadioStateTests {
    @Test func test_init_when_manager_is_powered_on_then_state_is_poweredOn() {
        // When
        let state = BluetoothRadioState(CBManagerState.poweredOn)

        // Then
        #expect(state == .poweredOn)
    }

    @Test func test_init_when_manager_is_powered_off_then_state_is_poweredOff() {
        // When
        let state = BluetoothRadioState(CBManagerState.poweredOff)

        // Then
        #expect(state == .poweredOff)
    }

    @Test(arguments: [CBManagerState.unknown, .resetting, .unsupported, .unauthorized])
    func test_init_when_manager_state_does_not_tell_power_then_state_is_unknown(managerState: CBManagerState) {
        // When
        let state = BluetoothRadioState(managerState)

        // Then
        #expect(state == .unknown)
    }
}

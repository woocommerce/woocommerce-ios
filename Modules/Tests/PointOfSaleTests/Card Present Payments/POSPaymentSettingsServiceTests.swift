import Testing
import Foundation
import Storage
@testable import PointOfSale

struct POSPaymentSettingsServiceTests {
    private let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).plist")

    @Test func isPaymentSuccessSoundEnabled_when_nothing_is_stored_then_returns_true() {
        // Given
        let sut = makeService()

        // When
        let isEnabled = sut.isPaymentSuccessSoundEnabled

        // Then
        #expect(isEnabled == true)
    }

    @Test(arguments: [false, true])
    func setPaymentSuccessSoundEnabled_when_read_by_a_new_instance_then_returns_the_saved_value(isEnabled: Bool) {
        // Given
        makeService().setPaymentSuccessSoundEnabled(!isEnabled)

        // When
        makeService().setPaymentSuccessSoundEnabled(isEnabled)

        // Then
        #expect(makeService().isPaymentSuccessSoundEnabled == isEnabled)
        try? FileManager.default.removeItem(at: fileURL)
    }
}

private extension POSPaymentSettingsServiceTests {
    /// A new instance over the same file stands in for reading the setting after an app restart.
    func makeService() -> POSPaymentSettingsService {
        POSPaymentSettingsService(generalAppSettings: GeneralAppSettingsStorage(fileStorage: PListFileStorage(), fileURL: fileURL))
    }
}

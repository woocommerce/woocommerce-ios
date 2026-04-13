import Foundation
import Observation

/// Manages PIN state for local staff settings.
///
/// Extracted from `POSStaffSettingsLocalView` to make PIN management logic testable
/// independently of SwiftUI. Wraps `POSPINService` and exposes observable state
/// for whether admin/cashier PINs are configured.
@Observable
final class POSStaffPINManager {
    private(set) var adminPINSet: Bool = false
    private(set) var cashierPINSet: Bool = false

    private let pinService: POSPINService

    init(pinService: POSPINService) {
        self.pinService = pinService
        refresh()
    }

    /// Re-reads PIN status from the underlying service.
    func refresh() {
        adminPINSet = pinService.hasPIN(for: .manager)
        cashierPINSet = pinService.hasPIN(for: .cashier)
    }

    /// Validates and stores a PIN for the given role.
    /// - Returns: `true` if the PIN was valid and stored, `false` if the format was invalid.
    func setPIN(_ pin: String, for role: PINRole) -> Bool {
        guard pinService.isValidFormat(pin) else { return false }
        pinService.setPIN(pin, for: role)
        refresh()
        return true
    }

    /// Removes all stored PINs.
    func clearAllPINs() {
        pinService.deletePIN(for: .manager)
        pinService.deletePIN(for: .cashier)
        refresh()
    }

    /// Whether at least one PIN (admin or cashier) is configured.
    var hasAnyPINs: Bool {
        adminPINSet || cashierPINSet
    }
}

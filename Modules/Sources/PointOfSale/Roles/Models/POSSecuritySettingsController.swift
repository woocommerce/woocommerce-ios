import Foundation
import Observation

@MainActor
@Observable
final class POSSecuritySettingsController {
    private(set) var roles: Set<POSLocalRole>?
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private(set) var isConfirmingAdminRemoval = false
    private let store: POSPINManaging
    private let session: POSAccessSession

    init(store: POSPINManaging, session: POSAccessSession) {
        self.store = store
        self.session = session
    }

    var isVisible: Bool {
        !session.isLocked && session.allows(.manageStoreSettings)
    }

    var isPINProtectionEnabled: Bool { session.isPINProtectionEnabled }

    var offersCashierPINSetup: Bool { roles?.contains(.admin) == true }

    var hasOnlyAdminPIN: Bool { roles == [.admin] }

    func load() {
        do {
            try session.refreshPINProtection()
            roles = try store.configuredRoles()
            error = nil
        } catch {
            roles = nil
            self.error = error
        }
    }

    func makePINSetupController(for role: POSLocalRole) -> POSPINSetupController {
        POSPINSetupController { pin in await self.save(pin, for: role) }
    }

    func requestRemoval(for role: POSLocalRole) async {
        guard isVisible, !isSaving else { return }
        if role == .admin {
            isConfirmingAdminRemoval = true
        } else {
            _ = await save(nil, for: role)
        }
    }

    func cancelRemoval() {
        isConfirmingAdminRemoval = false
    }

    @discardableResult
    func confirmAdminRemoval() -> Task<Bool, Never>? {
        guard isConfirmingAdminRemoval else { return nil }
        isConfirmingAdminRemoval = false
        return Task { await save(nil, for: .admin) }
    }

    func save(_ pin: String?, for role: POSLocalRole) async -> Bool {
        guard isVisible, !isSaving, roles != nil else { return false }
        let change: POSPINChangeRegistration
        do {
            change = try session.beginPINChange()
        } catch {
            self.error = error
            return false
        }
        isSaving = true
        defer {
            change.finish()
            isSaving = false
        }
        do {
            let store = store
            try await Task.detached {
                if let pin { try store.setPIN(pin, for: role) } else { try store.removePIN(for: role) }
            }.value
            load()
            return error == nil
        } catch {
            load()
            self.error = (error as? POSPINStoreError) ?? .storageFailure
            return false
        }
    }
}

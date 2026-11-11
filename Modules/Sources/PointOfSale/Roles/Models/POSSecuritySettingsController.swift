import Foundation
import Observation

@MainActor
@Observable
final class POSSecuritySettingsController {
    private(set) var roles: Set<POSLocalRole>?
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private let store: POSPINManaging
    private let session: POSAccessSession

    init(store: POSPINManaging, session: POSAccessSession) {
        self.store = store
        self.session = session
    }

    var isVisible: Bool {
        POSSecuritySettingsViewHelper.canManage(isProtected: session.isPINProtectionEnabled,
                                               isLocked: session.isLocked,
                                               canManageSettings: session.currentStaff?.hasCapability(.manageStoreSettings) == true)
    }

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

    func save(_ pin: String?, for role: POSLocalRole) async -> Bool {
        guard isVisible, !isSaving, roles != nil else { return false }
        isSaving = true
        defer { isSaving = false }
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

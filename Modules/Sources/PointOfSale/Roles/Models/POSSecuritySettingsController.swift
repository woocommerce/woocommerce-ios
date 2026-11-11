import Foundation
import Observation

@MainActor
@Observable
final class POSSecuritySettingsController {
    private(set) var roles: Set<POSRole>?
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private let store: POSPINManaging
    private let session: POSAccessSession

    init(store: POSPINManaging, session: POSAccessSession) {
        self.store = store
        self.session = session
    }

    var isVisible: Bool {
        session.allows(.manageStoreSettings) && POSSecuritySettingsViewHelper.canManage(isProtected: session.isPINProtectionEnabled,
                                               isLocked: session.isLocked, role: session.currentStaff?.role)
    }

    func load() {
        do {
            try session.refreshPINProtection()
            roles = Set(try store.credentials().map { $0.staff.role })
            error = nil
        } catch {
            roles = nil
            self.error = error
        }
    }

    func save(_ pin: String?, for role: POSRole) async -> Bool {
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

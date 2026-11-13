import Foundation
import Observation

@MainActor
@Observable
final class POSSecuritySettingsController {
    private(set) var roles: Set<POSLocalRole>?
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private var removalRequestID: UUID?
    private var isVerifyingRemoval = false
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

    var isPINProtectionEnabled: Bool { session.isPINProtectionEnabled }

    var offersCashierPINSetup: Bool { roles?.contains(.admin) == true }

    var hasOnlyAdminPIN: Bool { roles == [.admin] }

    var isApprovingProtectionRemoval: Bool { removalRequestID != nil }

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
        guard role != .admin else { return }
        _ = await save(nil, for: role)
    }

    func requestProtectionRemoval(using handler: POSManagerOverrideHandler, reason: String) {
        guard isVisible, !isSaving, roles?.contains(.admin) == true else { return }
        handler.requestApproval(for: .manageStoreSettings,
                                reason: reason,
                                submitPIN: approveProtectionRemoval,
                                onCancel: cancelRemoval)
        removalRequestID = UUID()
    }

    func cancelRemoval() {
        removalRequestID = nil
    }

    func approveProtectionRemoval(withPIN pin: String) async throws(POSAuthError) -> Bool {
        guard let requestID = removalRequestID, isVisible, !isSaving, !isVerifyingRemoval, !Task.isCancelled else { return false }
        isVerifyingRemoval = true
        defer { isVerifyingRemoval = false }
        do {
            try await session.requestManagerApproval(withPIN: pin, for: .manageStoreSettings)
        } catch {
            guard removalRequestID == requestID, !Task.isCancelled else { return false }
            throw error
        }
        guard removalRequestID == requestID, isVisible, !Task.isCancelled else { return false }
        let removed = await save(nil, for: .admin)
        if removed, removalRequestID == requestID {
            cancelRemoval()
        }
        return removed
    }

    private func save(_ pin: String?, for role: POSLocalRole) async -> Bool {
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

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
        POSPINSetupController(validatePIN: { pin in try await self.validatePIN(pin, for: role) },
                              savePIN: { pin in await self.save(pin, for: role) })
    }

    func requestRemoval(for role: POSLocalRole) async {
        guard role != .admin else { return }
        _ = await save(nil, for: role)
    }

    func requestProtectionRemoval(using handler: POSManagerOverrideHandler,
                                  reason: String) async -> POSManagerOverrideHandler.ApprovalResult {
        guard isVisible, !isSaving, roles?.contains(.admin) == true, !Task.isCancelled else { return .cancelled }
        let requestID = UUID()
        removalRequestID = requestID
        defer {
            if removalRequestID == requestID { removalRequestID = nil }
        }
        return await handler.requestApproval(for: .manageStoreSettings, reason: reason, operation: { pin throws(POSAuthError) in
            try await self.approveProtectionRemoval(withPIN: pin, requestID: requestID)
        })
    }

    private func approveProtectionRemoval(withPIN pin: String, requestID: UUID) async throws(POSAuthError) -> Bool {
        guard removalRequestID == requestID, isVisible, !isSaving, !isVerifyingRemoval, !Task.isCancelled else { return false }
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
        return removed
    }

    private func validatePIN(_ pin: String, for role: POSLocalRole) async throws {
        guard isVisible, !isSaving, roles != nil, !Task.isCancelled else { throw CancellationError() }
        isSaving = true
        defer { isSaving = false }
        let store = store
        let result = await Task.detached { try store.validatePIN(pin, for: role) }.result
        guard isVisible, !Task.isCancelled else { throw CancellationError() }
        try result.get()
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

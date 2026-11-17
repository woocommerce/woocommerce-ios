import Foundation
import Observation

enum POSPINAction: Equatable {
    case setUp
    case change
    case delete
}

@MainActor
@Observable
final class POSSecuritySettingsController {
    private(set) var roles: Set<POSLocalRole>?
    private(set) var isSaving = false
    private(set) var error: POSPINStoreError?
    private enum ApprovalAction {
        case removeProtection
        case changeAdminPIN
    }
    private struct ApprovalRequest: Equatable {
        let id = UUID()
        let scope: POSPINSessionTokens.Token
        let action: ApprovalAction
    }
    private var approvalRequest: ApprovalRequest?
    private var isVerifyingApproval = false
    private var editorID: UUID?
    private let store: POSPINManaging
    private let session: POSAccessSession
    private let lockSettings: POSLockSettings?
    private let flowSleep: @MainActor (Duration) async throws -> Void

    init(store: POSPINManaging, session: POSAccessSession, lockSettings: POSLockSettings? = nil,
         flowSleep: @escaping @MainActor (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) {
        self.store = store
        self.session = session
        self.lockSettings = lockSettings
        self.flowSleep = flowSleep
    }

    var isVisible: Bool {
        !session.isLocked && session.allows(.manageStoreSettings)
    }

    var isPINProtectionEnabled: Bool { session.isPINProtectionEnabled }

    var offersCashierPINSetup: Bool { roles?.contains(.admin) == true }

    var isApprovingProtectionRemoval: Bool { approvalRequest?.action == .removeProtection }

    var hasOnlyAdminPIN: Bool { roles == [.admin] }

    var lockPreferences: POSLockPreferences? { lockSettings?.preferences }

    /// The Admin PIN can only be changed; turning protection off is the way to remove it.
    func pinActions(for role: POSLocalRole) -> [POSPINAction] {
        guard let roles, role == .admin || offersCashierPINSetup else { return [] }
        guard roles.contains(role) else { return [.setUp] }
        return role == .admin ? [.change] : [.change, .delete]
    }

    func updateLockPreferences(_ change: (inout POSLockPreferences) -> Void) {
        guard isVisible, isPINProtectionEnabled, !isSaving else { return }
        lockSettings?.update(change)
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

    func makePINSetupFlow(for role: POSLocalRole) -> POSPINSetupFlow {
        let configuration: POSPINSetupFlow.Configuration
        switch role {
        case .admin: configuration = .initialAdmin
        case .cashier: configuration = .cashier
        }
        let setup = makePINSetupController(for: configuration.role)
        return POSPINSetupFlow(configuration: configuration, setup: setup, sleep: flowSleep)
    }

    func makePINSetupController(for role: POSLocalRole) -> POSPINSetupController {
        makePINSetupController(for: role, permitsAdminChange: false)
    }

    func endPINEditing() {
        editorID = nil
    }

    private func makePINSetupController(for role: POSLocalRole, permitsAdminChange: Bool) -> POSPINSetupController {
        let id = UUID()
        let scope = session.accessScope
        let isAuthorized = role != .admin || roles?.contains(.admin) == false || permitsAdminChange
        editorID = id
        return POSPINSetupController(validatePIN: { pin in
            guard isAuthorized, self.isCurrentEditor(id, scope: scope) else { throw CancellationError() }
            try await self.validatePIN(pin, for: role, editorID: id, scope: scope)
        }, savePIN: { pin throws(POSPINStoreError) in
            guard isAuthorized, self.isCurrentEditor(id, scope: scope) else { return false }
            let saved = await self.save(pin, for: role, editorID: id, scope: scope)
            if !saved, let error = self.error { throw error }
            return saved
        })
    }

    private func isCurrentEditor(_ id: UUID, scope: POSPINSessionTokens.Token) -> Bool {
        editorID == id && session.accessScope == scope && isVisible && !Task.isCancelled
    }

    func requestRemoval(for role: POSLocalRole) async {
        guard role != .admin else { return }
        _ = await save(nil, for: role)
    }

    func requestProtectionRemoval(using handler: POSManagerOverrideHandler,
                                  reason: String) async -> POSManagerOverrideHandler.ApprovalResult {
        await requestApproval(.removeProtection, using: handler, reason: reason)
    }

    func requestAdminPINChange(using handler: POSManagerOverrideHandler, reason: String) async -> POSPINSetupFlow? {
        let scope = session.accessScope
        guard await requestApproval(.changeAdminPIN, using: handler, reason: reason) == .completed,
              session.accessScope == scope, isVisible, !Task.isCancelled else { return nil }
        let configuration = POSPINSetupFlow.Configuration.adminChange
        let setup = makePINSetupController(for: configuration.role, permitsAdminChange: true)
        return POSPINSetupFlow(configuration: configuration, setup: setup, sleep: flowSleep)
    }

    private func requestApproval(_ action: ApprovalAction, using handler: POSManagerOverrideHandler,
                                 reason: String) async -> POSManagerOverrideHandler.ApprovalResult {
        guard isVisible, !isSaving, roles?.contains(.admin) == true, !Task.isCancelled else { return .cancelled }
        handler.configure(session: session)
        endPINEditing()
        let request = ApprovalRequest(scope: session.accessScope, action: action)
        approvalRequest = request
        defer {
            if approvalRequest == request { approvalRequest = nil }
        }
        let result = await handler.requestApproval(for: .manageStoreSettings, reason: reason, operation: { pin throws(POSAuthError) in
            try await self.approve(withPIN: pin, request: request)
        })
        guard approvalRequest == request, !Task.isCancelled else { return .cancelled }
        return result
    }

    private func approve(withPIN pin: String, request: ApprovalRequest) async throws(POSAuthError) -> Bool {
        guard isCurrentApproval(request), !isSaving, !isVerifyingApproval else { return false }
        isVerifyingApproval = true
        defer { isVerifyingApproval = false }
        do {
            try await session.requestManagerApproval(withPIN: pin, for: .manageStoreSettings)
        } catch {
            guard isCurrentApproval(request) else { return false }
            throw error
        }
        guard isCurrentApproval(request) else { return false }
        switch request.action {
        case .changeAdminPIN: return true
        case .removeProtection: return await save(nil, for: .admin)
        }
    }

    private func isCurrentApproval(_ request: ApprovalRequest) -> Bool {
        approvalRequest == request && session.accessScope == request.scope && isVisible && !Task.isCancelled
    }

    private func validatePIN(_ pin: String, for role: POSLocalRole,
                             editorID: UUID, scope: POSPINSessionTokens.Token) async throws {
        guard isVisible, !isSaving, roles != nil, !Task.isCancelled else { throw CancellationError() }
        isSaving = true
        defer { isSaving = false }
        let store = store
        let result = await Task.detached { try store.validatePIN(pin, for: role) }.result
        guard isCurrentEditor(editorID, scope: scope) else { throw CancellationError() }
        try result.get()
    }

    private func save(_ pin: String?, for role: POSLocalRole,
                      editorID: UUID? = nil, scope: POSPINSessionTokens.Token? = nil) async -> Bool {
        guard isVisible, !isSaving, roles != nil, !Task.isCancelled else { return false }
        let change = session.beginPINChange()
        isSaving = true
        defer {
            change.finish()
            isSaving = false
        }
        do {
            let store = store
            if let pin {
                let preparation = await Task.detached { try store.preparePIN(pin, for: role) }.result
                guard let editorID, let scope, isCurrentEditor(editorID, scope: scope) else { return false }
                let commit = try preparation.get()
                try commit()
                self.editorID = nil
            } else {
                try await Task.detached { try store.removePIN(for: role) }.value
            }
            load()
            return error == nil
        } catch {
            load()
            self.error = (error as? POSPINStoreError) ?? .storageFailure
            return false
        }
    }
}

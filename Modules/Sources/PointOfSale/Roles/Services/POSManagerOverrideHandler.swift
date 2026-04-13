import Foundation

/// Encapsulates the manager override flow: checking permissions, presenting the PIN modal,
/// validating the PIN, and calling back on approval.
///
/// Multiple views (order details, item list, floating controls, staff settings) duplicate
/// this pattern. This handler extracts the shared logic into a testable unit.
///
/// Usage from a view:
/// ```swift
/// @State private var overrideHandler = POSManagerOverrideHandler()
///
/// // Request permission (the handler checks and shows the modal if needed)
/// overrideHandler.requestPermission(
///     for: .refundOrders,
///     permissions: permissions,
///     onApproved: { token in processRefund(token: token) }
/// )
/// ```
@MainActor
@Observable
final class POSManagerOverrideHandler {
    private(set) var overrideState: POSManagerOverrideState = .awaitingPIN
    var isShowingOverride: Bool = false

    private var onApproved: ((String?) -> Void)?
    private var activeCapability: String?
    private var activeOrderID: Int64?

    /// Checks whether the action requires override and shows the modal if needed.
    /// - Parameters:
    ///   - capability: The capability to check.
    ///   - permissions: The permission provider to check against.
    ///   - orderID: Optional order ID for context (e.g. refunds).
    ///   - onApproved: Called with the approval token (or nil for local mode) when the action is authorized.
    /// - Returns: `true` if the action was allowed immediately (no override needed).
    @discardableResult
    func requestPermission(for capability: POSCapability,
                           permissions: POSPermissionProviding,
                           orderID: Int64? = nil,
                           onApproved: @escaping (String?) -> Void) -> Bool {
        let result = permissions.checkPermission(capability)
        switch result {
        case .allowed:
            onApproved(nil)
            return true
        case .requiresOverride:
            self.onApproved = onApproved
            self.activeCapability = capability.rawValue
            self.activeOrderID = orderID
            overrideState = .awaitingPIN
            isShowingOverride = true
            return false
        }
    }

    /// Handles a PIN entered in the override modal.
    /// Validates the PIN via the permission provider and transitions state accordingly.
    func handlePINEntered(_ pin: String, permissions: POSPermissionProviding) async {
        guard let capability = activeCapability else { return }
        do {
            let token = try await permissions.requestManagerApproval(
                managerPIN: pin,
                for: capability,
                orderID: activeOrderID
            )
            overrideState = .approved
            try? await Task.sleep(for: .milliseconds(500))
            isShowingOverride = false
            onApproved?(token)
            onApproved = nil
            activeCapability = nil
            activeOrderID = nil
        } catch {
            overrideState = .error(message: error.posOverrideErrorMessage)
        }
    }

    /// Cancels the override flow and hides the modal.
    func cancel() {
        isShowingOverride = false
        onApproved = nil
        activeCapability = nil
        activeOrderID = nil
    }
}

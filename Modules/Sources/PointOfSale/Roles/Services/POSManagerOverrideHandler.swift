import Foundation

/// Encapsulates the manager override flow: checking permissions, presenting the PIN modal,
/// validating the PIN, and calling back on approval.
///
/// Multiple views (order details, item list, floating controls, staff settings) need
/// this pattern. This handler extracts the shared logic into a testable, reusable unit.
///
/// Usage from a view:
/// ```swift
/// @State private var overrideHandler = POSManagerOverrideHandler()
///
/// // 1. Request permission (checks capability, shows modal only if needed)
/// overrideHandler.requestPermission(
///     for: .refundOrders,
///     actionDescription: "Issue a refund for Order #1042",
///     permissions: permissions,
///     orderID: orderID,
///     onApproved: { token in processRefund(token: token) }
/// )
///
/// // 2. Attach the modal (once per view)
/// .posModal(isPresented: $overrideHandler.isShowingOverride) {
///     overrideHandler.makeOverrideView(permissions: permissions)
/// }
/// ```
@MainActor
@Observable
final class POSManagerOverrideHandler {
    private(set) var overrideState: POSManagerOverrideState = .awaitingPIN
    var isShowingOverride: Bool = false

    /// Description shown in the override modal (e.g. "Issue a refund for Order #1042").
    private(set) var actionDescription: String = ""

    /// Raw capability string passed to the override modal.
    private(set) var activeCapability: String?

    private var onApproved: ((String?) -> Void)?
    private var activeOrderID: Int64?

    /// Checks whether the action requires override and shows the modal if needed.
    ///
    /// If the current operator has the capability, `onApproved` is called immediately
    /// with `nil` (no token needed). Otherwise the override modal is shown.
    ///
    /// - Parameters:
    ///   - capability: The capability to check.
    ///   - actionDescription: Human-readable description for the override modal.
    ///   - permissions: The permission provider to check against.
    ///   - orderID: Optional order ID for context (e.g. refunds).
    ///   - onApproved: Called with the approval token (or nil) when the action is authorized.
    /// - Returns: `true` if the action was allowed immediately (no override needed).
    @discardableResult
    func requestPermission(for capability: POSCapability,
                           actionDescription: String,
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
            self.actionDescription = actionDescription
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
            // Delay the approved callback to let the modal dismiss animation complete
            // before the caller presents another view (e.g. exit confirmation modal).
            let approvedCallback = onApproved
            let approvedToken = token
            cleanup()
            try? await Task.sleep(for: .milliseconds(300))
            approvedCallback?(approvedToken)
        } catch {
            overrideState = .error(message: error.posOverrideErrorMessage)
        }
    }

    /// Cancels the override flow and hides the modal.
    func cancel() {
        isShowingOverride = false
        cleanup()
    }

    private func cleanup() {
        onApproved = nil
        activeCapability = nil
        activeOrderID = nil
    }
}

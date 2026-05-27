import Foundation
import struct Networking.MetaData

/// Outcome of a successful permission request — either the operator already had the
/// capability, or a manager authorized them.
struct POSPermissionGrant: Equatable {
    /// The approving manager's user id when an override happened, `nil` when the operator
    /// already had the capability themselves. Callers attach this to `_pos_override_user_id`
    /// meta when sending the gated request.
    let overrideUserID: Int64?

    /// The capability that was authorized, written to `_pos_override_reason` when
    /// `overrideUserID` is non-nil.
    let overrideReason: String?

    /// Convenience: no override needed (operator had the cap).
    static var allowed: POSPermissionGrant {
        POSPermissionGrant(overrideUserID: nil, overrideReason: nil)
    }

    /// Builds the `meta_data` entries to attach to a `POST /coupons` request that the
    /// cashier triggered. Returns `_pos_staff_user_id` always, plus the `_pos_override_*`
    /// pair when this grant came from a manager override.
    func couponCreationMetadata(staffUserID: Int64?) -> [MetaData] {
        var entries: [MetaData] = []
        if let staffUserID {
            entries.append(MetaData(metadataID: 0,
                                    key: "_pos_staff_user_id",
                                    value: String(staffUserID)))
        }
        if let overrideUserID, let overrideReason {
            entries.append(MetaData(metadataID: 0,
                                    key: "_pos_override_user_id",
                                    value: String(overrideUserID)))
            entries.append(MetaData(metadataID: 0,
                                    key: "_pos_override_reason",
                                    value: overrideReason))
        }
        return entries
    }
}

/// Encapsulates the manager override flow: checking permissions, presenting the PIN modal,
/// validating the PIN, and calling back on approval.
///
/// Multiple views (order details, item list, floating controls, staff settings) need this
/// pattern. This handler extracts the shared logic into a testable, reusable unit.
///
/// Usage from a view:
/// ```swift
/// @State private var overrideHandler = POSManagerOverrideHandler()
///
/// // 1. Request permission (checks capability, shows modal only if needed)
/// overrideHandler.requestPermission(
///     for: .refundShopOrders,
///     actionDescription: "Issue a refund for Order #1042",
///     permissions: permissions,
///     onApproved: { grant in processRefund(overrideUserID: grant.overrideUserID,
///                                          overrideReason: grant.overrideReason) }
/// )
///
/// // 2. Attach the modal (once per view)
/// .posManagerOverrideModal(handler: overrideHandler, permissions: permissions)
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

    private var onApproved: ((POSPermissionGrant) -> Void)?

    /// Checks whether the action requires override and shows the modal if needed.
    ///
    /// If the current operator has the capability, `onApproved` is called immediately
    /// with `.allowed` (no override). Otherwise the override modal is shown.
    ///
    /// - Returns: `true` if the action was allowed immediately (no override needed).
    @discardableResult
    func requestPermission(for capability: POSCapability,
                           actionDescription: String,
                           permissions: POSPermissionProviding,
                           onApproved: @escaping (POSPermissionGrant) -> Void) -> Bool {
        let result = permissions.checkPermission(capability)
        switch result {
        case .allowed:
            onApproved(.allowed)
            return true
        case .requiresOverride:
            self.onApproved = onApproved
            self.activeCapability = capability.rawValue
            self.actionDescription = actionDescription
            overrideState = .awaitingPIN
            isShowingOverride = true
            return false
        }
    }

    /// Handles a PIN entered in the override modal. Validates the PIN locally via
    /// `requestManagerApproval`; on success, invokes the stored callback with the
    /// approver's user id so the caller can attach `_pos_override_*` meta to the
    /// next request.
    func handlePINEntered(_ pin: String, permissions: POSPermissionProviding) async {
        guard let capability = activeCapability else { return }
        do {
            let approver = try await permissions.requestManagerApproval(
                managerPIN: pin,
                for: capability
            )
            overrideState = .approved
            try? await Task.sleep(for: .milliseconds(500))
            isShowingOverride = false
            // Delay the approved callback to let the modal dismiss animation complete
            // before the caller presents another view (e.g. refund review modal).
            let approvedCallback = onApproved
            let grant = POSPermissionGrant(overrideUserID: approver.userID,
                                           overrideReason: capability)
            cleanup()
            try? await Task.sleep(for: .milliseconds(300))
            approvedCallback?(grant)
        } catch {
            overrideState = .error(message: error.posOverrideErrorMessage)
        }
    }

    /// Cancels the override flow and hides the modal.
    func cancel() {
        isShowingOverride = false
        overrideState = .awaitingPIN
        cleanup()
    }

    private func cleanup() {
        onApproved = nil
        activeCapability = nil
    }
}

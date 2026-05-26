import Foundation

struct POSManagerOverrideRequest: Equatable, Identifiable {
    /// Unique per presentation so item-based modals refresh even when the same approval is requested again.
    let id = UUID()
    let capability: POSCapability
    let reason: String
}

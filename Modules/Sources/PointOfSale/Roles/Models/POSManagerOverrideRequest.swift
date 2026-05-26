import Foundation

struct POSManagerOverrideRequest: Equatable, Identifiable {
    let id = UUID()
    let capability: POSCapability
    let reason: String
}

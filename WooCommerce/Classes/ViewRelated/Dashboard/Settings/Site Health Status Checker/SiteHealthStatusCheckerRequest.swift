import Foundation

struct SiteHealthStatusCheckerRequest: Identifiable {

    let id = UUID()

    /// Name of the action. Eg. `Orders retrieve`
    ///
    let actionName: String

    /// Name of the endpoint. Eg. `Orders`
    ///
    let endpointName: String

    /// Result of the response
    ///
    let success: Bool

    /// The error, if available
    ///
    let error: Error?

    /// The time took for the request
    ///
    let time: TimeInterval?
}

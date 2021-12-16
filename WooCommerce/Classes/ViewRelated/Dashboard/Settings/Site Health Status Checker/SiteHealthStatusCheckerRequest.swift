import Foundation

struct SiteHealthStatusCheckerRequest: Identifiable {

    let id = UUID()

    /// Name of the action. Eg. `Orders retrieve`
    ///
    var actionName: String

    /// Name of the endpoint. Eg. `Orders`
    ///
    var endpointName: String

    /// Result of the response
    ///
    var success: Bool

    /// The error, if available
    ///
    var error: Error?

    /// The time took for the request
    ///
    var time: TimeInterval?
}

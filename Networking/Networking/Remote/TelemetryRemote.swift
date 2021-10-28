import Foundation


/// Site API: Remote Endpoints
///
public class TelemetryRemote: Remote {

    /// Posts data to the telemetry endpoint via the Jetpack tunnel for the provided siteID.
    /// Response is expected to be null.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the API settings.
    ///   - versionString: App version to report.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func postTelemetry(for siteID: Int64, versionString: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let path = "tracker"
        let parameters = ["platform": "ios", "version": versionString]
        let request = JetpackRequest(wooApiVersion: .wcTelemetry, method: .post, siteID: siteID, path: path, parameters: parameters)
        let mapper = IgnoringResponseMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

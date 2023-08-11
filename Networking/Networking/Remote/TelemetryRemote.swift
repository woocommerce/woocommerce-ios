import Foundation


/// Site API: Remote Endpoints
///
public class TelemetryRemote: Remote {

    /// Sends data to the telemetry endpoint via the Jetpack tunnel for the provided siteID.
    /// Response is expected to be null.
    ///
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the API settings.
    ///   - versionString: App version to report.
    ///   - installationDate: App installation date if available. If the date is unavailable (e.g. for earlier app versions), the date
    ///     parameter is not included.
    ///   - completion: Closure to be executed upon completion.
    ///
    public func sendTelemetry(for siteID: Int64, versionString: String, installationDate: Date?, completion: @escaping (Result<Void, Error>) -> Void) {
        let path = "tracker"
        let parameters = ["platform": "ios",
                          "version": versionString,
                          "installation_date": installationDate?.ISO8601Format()].compactMapValues { $0 } as [String: Any]
        let request = JetpackRequest(wooApiVersion: .wcTelemetry,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = IgnoringResponseMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

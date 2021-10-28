import Foundation
import Networking


/// TelemetryAction: Defines all of the Actions supported by the TelemetryStore.
///
public enum TelemetryAction: Action {

    /// Posts data to the telemetry endpoint.
    ///
    case postTelemetry(siteID: Int64, versionString: String, onCompletion: (Result<Void, Error>) -> Void)
}

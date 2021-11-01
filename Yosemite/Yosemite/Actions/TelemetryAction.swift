import Foundation
import Networking


/// TelemetryAction: Defines all of the Actions supported by the TelemetryStore.
///
public enum TelemetryAction: Action {

    /// Sends data to the telemetry endpoint.
    ///
    case sendTelemetry(siteID: Int64, versionString: String, telemetryLastReportedTime: Date?, onCompletion: (Result<Void, Error>) -> Void)
}

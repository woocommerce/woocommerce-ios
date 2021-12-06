import Foundation

public final class WCScaleRemote: Remote {
    /// Loads a WCPay connection token for a given site ID and parses the rsponse
    /// - Parameters:
    ///   - siteID: Site for which we'll fetch the WCPay Connection token.
    ///   - completion: Closure to be executed upon completion.
    public func fetchScaleStatus(for siteID: Int64,
                                    completion: @escaping(Result<WCScaleStatus, Error>) -> Void) {
        let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: Path.status)

        let mapper = WCScaleMapper()

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants!
//
private extension WCScaleRemote {
    enum Path {
        static let status = "connect/scale/1/weight"
    }
}

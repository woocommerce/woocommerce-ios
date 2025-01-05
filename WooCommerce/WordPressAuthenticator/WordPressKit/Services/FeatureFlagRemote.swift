import UIKit

open class FeatureFlagRemote: ServiceRemoteWordPressComREST {

    public typealias FeatureFlagResponseCallback = (Result<FeatureFlagList, Error>) -> Void

    public enum FeatureFlagRemoteError: Error {
        case InvalidDataError
    }

    open func getRemoteFeatureFlags(forDeviceId deviceId: String, callback: @escaping FeatureFlagResponseCallback) {
        let params = SessionDetails(deviceId: deviceId)
        let endpoint = "mobile/feature-flags"
        let path = self.path(forEndpoint: endpoint, withVersion: ._2_0)
        var dictionary: [String: AnyObject]?

        do {
            dictionary = try params.dictionaryRepresentation()
        } catch let error {
            callback(.failure(error))
            return
        }

        wordPressComRESTAPI.get(path,
                                parameters: dictionary,
                                success: { response, _ in

                                    if let featureFlagList = response as? NSDictionary {

                                        let reconstitutedList = featureFlagList.compactMap { row -> FeatureFlag? in
                                            guard
                                                let title = row.key as? String,
                                                let value = row.value as? Bool
                                                else {
                                                    return nil
                                                }

                                            return FeatureFlag(title: title, value: value)
                                        }.sorted()

                                        callback(.success(reconstitutedList))
                                    } else {
                                        callback(.failure(FeatureFlagRemoteError.InvalidDataError))
                                    }

                                }, failure: { error, response in
                                    WPAuthenticatorLogError("Error retrieving remote feature flags")
                                    WPAuthenticatorLogError("\(error)")

                                    if let response = response {
                                        WPAuthenticatorLogDebug("Response Code: \(response.statusCode)")
                                    }

                                    callback(.failure(error))
                                })
    }
}

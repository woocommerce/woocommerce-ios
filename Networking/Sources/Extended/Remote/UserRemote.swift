import Foundation

/// User: Remote Endpoints
///
public final class UserRemote: Remote {
    /// Loads the User associated with the site ID.
    /// This should be able to fetch from both dotcom and Jetpack-connected sites.
    /// - Parameters:
    ///    - siteID: The dotcom site ID.
    ///    - completion: The block to be executed once the request completes.
    public func loadUserInfo(for siteID: Int64, completion: @escaping(Result<User, Error>) -> Void) {
        let path = Constants.usersPath
        let parameters = [
            "context": "edit",
            "fields": "id,username,id_wpcom,email,first_name,last_name,nickname,roles"
        ]
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: siteID, path: path, parameters: parameters, availableAsRESTRequest: true)
        let mapper = UserMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}

// MARK: - Constants!
//
private extension UserRemote {
    enum Constants {
        static let usersPath: String = "wp/v2/users/me"
    }
}

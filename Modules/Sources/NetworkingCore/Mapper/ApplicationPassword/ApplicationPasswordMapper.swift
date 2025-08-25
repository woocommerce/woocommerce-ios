import Foundation

struct ApplicationPasswordMapper: Mapper {
    /// WordPress org username that the application password belongs to
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because wpOrgUsername is not returned from the endpoint
    ///
    let wpOrgUsername: String

    func map(response: Data) throws -> ApplicationPassword {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .wpOrgUsername: wpOrgUsername
        ]
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ApplicationPasswordEnvelope.self, from: response).applicationPassword
        } else {
            return try decoder.decode(ApplicationPassword.self, from: response)
        }
    }
}

/// ApplicationPassword Disposable Entity:
/// When generating application password with Jetpack proxy, the result is returned within the `data` key.
/// This entity allows us to do parse data with JSONDecoder.
///
private struct ApplicationPasswordEnvelope: Decodable {
    let applicationPassword: ApplicationPassword

    private enum CodingKeys: String, CodingKey {
        case applicationPassword = "data"
    }
}

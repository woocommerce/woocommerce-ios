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
            return try decoder.decode(ApplicationPasswordEnvelope.self, from: response).data
        } else {
            return try decoder.decode(ApplicationPassword.self, from: response)
        }
    }
}

private struct ApplicationPasswordEnvelope: Decodable {
    let data: ApplicationPassword
}


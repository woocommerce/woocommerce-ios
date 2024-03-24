import Foundation

struct ApplicationPasswordMapper: Mapper {
    /// WordPress org username that the application password belongs to
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because wpOrgUsername is not returned from the endpoint
    ///
    let wpOrgUsername: String

    /// SiteURL that the application password belongs to
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because siteURL is not returned from the endpoint
    ///
    let siteURL: String

    func map(response: Data) throws -> ApplicationPassword {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .wpOrgUsername: wpOrgUsername,
            .siteURL: siteURL
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

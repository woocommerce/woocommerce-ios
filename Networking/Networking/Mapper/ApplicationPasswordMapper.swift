import Foundation

struct ApplicationPasswordMapper: Mapper {
    private struct ApplicationPassword: Decodable {
        let password: String
    }

    private struct ApplicationPasswordEnvelope: Decodable {
        let password: ApplicationPassword

        private enum CodingKeys: String, CodingKey {
            case password = "data"
        }
    }

    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(ApplicationPasswordEnvelope.self, from: response).password.password
    }
}

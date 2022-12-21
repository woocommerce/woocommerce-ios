import Foundation

struct ApplicationPasswordMapper: Mapper {
    private struct ApplicationPassword: Decodable {
        let password: String
    }

    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(ApplicationPassword.self, from: response).password
    }
}

import Foundation

struct ApplicationPasswordNameAndUUIDMapper: Mapper {
    func map(response: Data) throws -> [ApplicationPasswordNameAndUUID] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ApplicationNameAndUUIDEnvelope.self, from: response).data
        } else {
            return try decoder.decode([ApplicationPasswordNameAndUUID].self, from: response)
        }

    }
}

private struct ApplicationNameAndUUIDEnvelope: Decodable {
    let data: [ApplicationPasswordNameAndUUID]
}

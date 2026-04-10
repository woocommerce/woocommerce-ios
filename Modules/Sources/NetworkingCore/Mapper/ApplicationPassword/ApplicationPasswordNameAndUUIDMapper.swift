import Foundation

struct ApplicationPasswordNameAndUUIDMapper: Mapper {
    func map(response: Data) throws -> [ApplicationPasswordNameAndUUID] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ApplicationPasswordNameAndUUIDEnvelope.self, from: response).data
        } else {
            return try decoder.decode([ApplicationPasswordNameAndUUID].self, from: response)
        }
    }
}

/// ApplicationPasswordNameAndUUID Disposable Entity:
/// When retrieving application password with Jetpack proxy, the result is returned within the `data` key.
/// This entity allows us to do parse data with JSONDecoder.
///
private struct ApplicationPasswordNameAndUUIDEnvelope: Decodable {
    let data: [ApplicationPasswordNameAndUUID]
}

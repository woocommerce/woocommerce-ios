import Foundation

struct ApplicationPasswordNameAndUUIDMapper: Mapper {
    func map(response: Data) throws -> [ApplicationPasswordNameAndUUID] {
        let decoder = JSONDecoder()
        return try decoder.decode([ApplicationPasswordNameAndUUID].self, from: response)
    }
}

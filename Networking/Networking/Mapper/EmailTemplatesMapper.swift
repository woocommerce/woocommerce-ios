import Foundation

struct EmailTemplate: Decodable {
    let id: String
}

struct EmailTemplatesMapper: Mapper {
    func map(response: Data) throws -> [EmailTemplate] {
        let decoder = JSONDecoder()
        if hasDataEnvelope(in: response) {
            return try decoder.decode(EmailTemplatesEnvelope.self, from: response).data
        } else {
            return try decoder.decode([EmailTemplate].self, from: response)
        }
    }
}

private struct EmailTemplatesEnvelope: Decodable {
    let data: [EmailTemplate]
}

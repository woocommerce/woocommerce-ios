import Foundation

/// Mapper: `AIProduct` generated using AI
///
struct AIProductMapper: Mapper {
    let siteID: Int64

    func map(response: Data) throws -> AIProduct {
        let decoder = JSONDecoder()
        let textCompletion = try decoder.decode(JetpackAIQueryResponse.self, from: response).aiResponse()
        return try decoder.decode(AIProduct.self, from: Data(textCompletion.utf8))
    }
}

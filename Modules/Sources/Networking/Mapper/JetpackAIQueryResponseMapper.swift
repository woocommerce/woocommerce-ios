
import Foundation

/// Mapper to parse the `jetpack-ai-query` endpoint response
///
struct JetpackAIQueryResponseMapper: Mapper {
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()
        return try decoder.decode(JetpackAIQueryResponse.self, from: response).aiResponse()
    }
}

struct JetpackAIQueryResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    private let choices: [Choice]

    func aiResponse() throws -> String {
        guard let choice = choices.first else {
            throw JetpackAIQueryResponseMapperError.noAIResponsefound
        }

        return choice.message.content
    }
}

enum JetpackAIQueryResponseMapperError: Error {
    case noAIResponsefound
}

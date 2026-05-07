import Foundation
import Yosemite

struct StoreActionDispatcher: Sendable {
    private let dispatchAction: @MainActor @Sendable (Action) -> Void

    init(dispatchAction: @escaping @MainActor @Sendable (Action) -> Void) {
        self.dispatchAction = dispatchAction
    }

    func dispatch<Value, Failure: Error>(
        _ makeAction: @escaping (@escaping (Result<Value, Failure>) -> Void) -> Action
    ) async -> Result<Value, Error> {
        let result: Result<Value, Failure> = await withCheckedContinuation { continuation in
            Task { @MainActor in
                dispatchAction(makeAction { result in
                    continuation.resume(returning: result)
                })
            }
        }
        return result.mapError { $0 }
    }
}

enum AssistantDataSourceError: LocalizedError {
    case notFound(String)
    case variableProductPrice(productID: Int64)

    var errorDescription: String? {
        switch self {
        case .notFound(let message):
            return message
        case .variableProductPrice(let productID):
            return "Product #\(productID) is a variable product; price lives on each variation, not the parent. " +
                "Call product_variations_list(product_id: \(productID)) to enumerate variations, then update each via product_variations_update."
        }
    }
}

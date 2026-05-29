import Foundation

public protocol AssistantIdGenerator: Sendable {
    func nextID() -> String
}

public struct UUIDAssistantIdGenerator: AssistantIdGenerator {
    public init() {}

    public func nextID() -> String {
        UUID().uuidString
    }
}

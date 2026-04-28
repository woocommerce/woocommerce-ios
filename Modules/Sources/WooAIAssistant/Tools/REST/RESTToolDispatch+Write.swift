import Foundation

extension RESTToolDispatch {
    static func dispatchEntityWrite(method: String,
                                    path: String,
                                    body: Data?,
                                    client: WCRESTClient,
                                    toolName: String,
                                    family: CardFamilyID,
                                    summarize: (AnyCodableJSON) -> AnyCodableJSON) async -> ToolResult {
        let idempotencyKey = UUID().uuidString
        let response = await client.request(method: method,
                                            path: path,
                                            query: nil,
                                            body: body,
                                            headers: ["Idempotency-Key": idempotencyKey])
        return WriteResultMapper.mapEntity(response,
                                           toolName: toolName,
                                           idempotencyKey: idempotencyKey,
                                           family: family,
                                           summarize: summarize)
    }

    static func dispatchBatchWrite(method: String,
                                   path: String,
                                   body: Data?,
                                   client: WCRESTClient,
                                   toolName: String,
                                   family: CardFamilyID) async -> ToolResult {
        let idempotencyKey = UUID().uuidString
        let response = await client.request(method: method,
                                            path: path,
                                            query: nil,
                                            body: body,
                                            headers: ["Idempotency-Key": idempotencyKey])
        return WriteResultMapper.mapBatch(response,
                                          toolName: toolName,
                                          idempotencyKey: idempotencyKey,
                                          family: family)
    }
}

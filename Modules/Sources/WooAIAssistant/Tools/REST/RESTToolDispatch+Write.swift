import Foundation

extension RESTToolDispatch {
    /// Generates a fresh idempotency key, dispatches the request, and routes
    /// the response through `WriteResultMapper.mapEntity`. Pulled out so the
    /// five write tools share one definition of the contract: every write
    /// gets a key, the key is the failure code on outcome_unknown, and the
    /// success path runs the family-specific summarizer.
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

    /// Batch counterpart to `dispatchEntityWrite`. The batch endpoint always
    /// answers 200 even when individual entries failed, so the mapper counts
    /// updates and surfaces per-entry errors instead of taking the envelope
    /// at face value.
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

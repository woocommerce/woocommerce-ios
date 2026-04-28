import Foundation

extension RESTToolDispatch {
    static func dispatchEntityWrite(method: String,
                                    path: String,
                                    body: Data?,
                                    client: WCRESTClient,
                                    toolName: String,
                                    family: CardFamilyID,
                                    summarize: (AnyCodableJSON) -> AnyCodableJSON) async -> ToolResult {
        let response = await client.request(method: method,
                                            path: path,
                                            query: nil,
                                            body: body)
        return WriteResultMapper.mapEntity(response,
                                           toolName: toolName,
                                           family: family,
                                           summarize: summarize)
    }

    static func dispatchBatchWrite(method: String,
                                   path: String,
                                   body: Data?,
                                   client: WCRESTClient,
                                   toolName: String,
                                   family: CardFamilyID) async -> ToolResult {
        let response = await client.request(method: method,
                                            path: path,
                                            query: nil,
                                            body: body)
        return WriteResultMapper.mapBatch(response,
                                         toolName: toolName,
                                         family: family)
    }
}

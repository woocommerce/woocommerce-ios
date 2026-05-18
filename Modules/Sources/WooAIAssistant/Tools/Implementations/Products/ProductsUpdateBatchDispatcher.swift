import Foundation
import CocoaLumberjackSwift

struct ProductsUpdateBatchDispatcher {

    let client: WCRESTClient

    func dispatch(plans: [EntryPlan]) async -> [BatchOutcome] {
        let batches = Self.groupIntoBatches(plans: plans)
        let client = client
        return await BoundedTaskGroup.runOrdered(batches, limit: ProductsUpdateTool.concurrencyCap) { batch in
            await Self.dispatchBatch(batch, client: client)
        }
    }

    /// Groups by destination endpoint and chunks each by `maxBatchSize` to stay under the WC cap.
    static func groupIntoBatches(plans: [EntryPlan]) -> [BatchCall] {
        var orderedDestinations: [BatchDestination] = []
        var bucket: [BatchDestination: [PlannedWrite]] = [:]
        for plan in plans {
            for write in plan.writes {
                let destination: BatchDestination
                if let parent = write.expandedParent, parent != write.targetID {
                    destination = .variations(parentID: parent)
                } else {
                    destination = .topLevel
                }
                if bucket[destination] == nil {
                    bucket[destination] = []
                    orderedDestinations.append(destination)
                }
                bucket[destination]?.append(write)
            }
        }
        var batches: [BatchCall] = []
        for destination in orderedDestinations {
            let writes = bucket[destination] ?? []
            guard !writes.isEmpty else { continue }
            for chunk in writes.chunked(into: ProductsUpdateTool.maxBatchSize) {
                batches.append(BatchCall(destination: destination, writes: chunk))
            }
        }
        return batches
    }

    static func buildBatchBody(_ writes: [PlannedWrite]) -> AnyCodableJSON {
        let entries = writes.map { write -> [String: AnyCodableJSON] in
            var entry = write.patch
            entry["id"] = .int(Int64(write.targetID))
            return entry
        }
        return .object(["update": .array(entries.map { .object($0) })])
    }

    private static func dispatchBatch(_ batch: BatchCall,
                                      client: WCRESTClient) async -> BatchOutcome {
        let body = buildBatchBody(batch.writes)
        let payload: Data
        do {
            payload = try JSONEncoder().encode(body)
        } catch {
            DDLogError("\(ProductsUpdateTool.name): failed to encode batch body for \(batch.destination.path): \(error)")
            let reasons = batch.writes.map { ($0.targetID, "could not serialize batch body") }
            return BatchOutcome(batch: batch, successes: [], failures: reasons, outcomeUnknownStatuses: [])
        }
        let response = await client.request(method: "POST",
                                            path: batch.destination.path,
                                            query: nil,
                                            body: payload)
        return parseBatchResponse(batch: batch, response: response)
    }

    static func parseBatchResponse(batch: BatchCall,
                                   response: WCRESTResponse) -> BatchOutcome {
        if HTTPStatusClassification.isOutcomeUnknownStatus(response.statusCode) {
            let reasons = batch.writes.map {
                ($0.targetID, "POST \(batch.destination.path) returned HTTP \(response.statusCode)")
            }
            let statuses = Array(repeating: response.statusCode, count: batch.writes.count)
            return BatchOutcome(batch: batch,
                                successes: [],
                                failures: reasons,
                                outcomeUnknownStatuses: statuses)
        }
        guard HTTPStatusClassification.isSuccess(response.statusCode) else {
            let reasons = batch.writes.map {
                ($0.targetID, "POST \(batch.destination.path) returned HTTP \(response.statusCode)")
            }
            return BatchOutcome(batch: batch, successes: [], failures: reasons, outcomeUnknownStatuses: [])
        }
        guard let payload = RESTResponseParsing.decodeJSON(response.data),
              let items = RESTResponseParsing.objectField(payload, "update").flatMap(RESTResponseParsing.arrayItems) else {
            let reasons = batch.writes.map {
                ($0.targetID, "POST \(batch.destination.path) returned an unexpected payload")
            }
            return BatchOutcome(batch: batch, successes: [], failures: reasons, outcomeUnknownStatuses: [])
        }
        var successes: [Int] = []
        var failures: [(Int, String)] = []
        for item in items {
            guard let identifier = RESTResponseParsing.intField(item, "id") else { continue }
            let targetID = Int(identifier)
            if let errorObject = RESTResponseParsing.objectField(item, "error") {
                let message = RESTResponseParsing.stringField(errorObject, "message") ?? "Batch entry failed"
                failures.append((targetID, message))
            } else {
                successes.append(targetID)
            }
        }
        return BatchOutcome(batch: batch,
                            successes: successes,
                            failures: failures,
                            outcomeUnknownStatuses: [])
    }
}

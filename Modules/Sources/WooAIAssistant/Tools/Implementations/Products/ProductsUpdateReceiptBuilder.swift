import Foundation

enum ProductsUpdateReceiptBuilder {

    static func build(plans: [EntryPlan],
                      outcomes: [BatchOutcome],
                      requestedCount: Int) -> RunReceipt {
        var updatedTargets: Set<Int> = []
        var failureNotes: [(Int, String)] = []
        var unknownStatuses: [Int] = []
        for outcome in outcomes {
            for success in outcome.successes {
                updatedTargets.insert(success)
            }
            failureNotes.append(contentsOf: outcome.failures)
            unknownStatuses.append(contentsOf: outcome.outcomeUnknownStatuses)
        }

        let updatedIDs = updatedIDs(plans: plans, successes: updatedTargets)
        let failed = failedPayload(plans: plans, notes: failureNotes)

        let partialSuccess = !updatedIDs.isEmpty && !failed.isEmpty
        let payload: AnyCodableJSON = .object([
            "tool": .string(ProductsUpdateTool.name),
            "requested_count": .int(Int64(requestedCount)),
            "updated_ids": .array(updatedIDs.map { .int(Int64($0)) }),
            "failed": .array(failed),
            "partial_success": .bool(partialSuccess)
        ])
        return RunReceipt(payload: payload, outcomeUnknownStatuses: unknownStatuses)
    }

    private static func updatedIDs(plans: [EntryPlan], successes: Set<Int>) -> [Int] {
        var updatedIDs: [Int] = []
        for plan in plans {
            for write in plan.writes where successes.contains(write.targetID) {
                updatedIDs.append(write.targetID)
            }
        }
        return updatedIDs
    }

    private static func failedPayload(plans: [EntryPlan],
                                      notes: [(Int, String)]) -> [AnyCodableJSON] {
        var failed: [AnyCodableJSON] = []
        for plan in plans {
            for failure in plan.preDispatchFailures {
                failed.append(failureNode(id: failure.0, reason: failure.1))
            }
        }
        for note in notes {
            failed.append(failureNode(id: note.0, reason: note.1))
        }
        return failed
    }

    private static func failureNode(id: Int, reason: String) -> AnyCodableJSON {
        .object([
            "id": .int(Int64(id)),
            "reason": .string(reason)
        ])
    }
}

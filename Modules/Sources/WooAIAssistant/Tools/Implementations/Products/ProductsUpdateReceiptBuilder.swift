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

        let updated = updatedTargetObjects(plans: plans, successes: updatedTargets)
        let failed = failedPayload(plans: plans, notes: failureNotes)

        let partialSuccess = !updated.isEmpty && !failed.isEmpty
        let payload: AnyCodableJSON = .object([
            "tool": .string(ProductsUpdateTool.name),
            "requested_count": .int(Int64(requestedCount)),
            "updated": .array(updated),
            "failed": .array(failed),
            "partial_success": .bool(partialSuccess)
        ])
        return RunReceipt(payload: payload, outcomeUnknownStatuses: unknownStatuses)
    }

    /// Each successful write becomes a target object the model can hand back to `show_cards` or
    /// `products_update`: variations carry `parent_id` so the right family is rendered.
    private static func updatedTargetObjects(plans: [EntryPlan], successes: Set<Int>) -> [AnyCodableJSON] {
        var updated: [AnyCodableJSON] = []
        for plan in plans {
            for write in plan.writes where successes.contains(write.targetID) {
                if let parentID = write.expandedParent {
                    updated.append(.object([
                        "kind": .string("variation"),
                        "id": .int(Int64(write.targetID)),
                        "parent_id": .int(Int64(parentID))
                    ]))
                } else {
                    updated.append(.object([
                        "kind": .string("product"),
                        "id": .int(Int64(write.targetID))
                    ]))
                }
            }
        }
        return updated
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

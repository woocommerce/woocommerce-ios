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

        let success = expandedPayload(plans: plans, successes: updatedTargets)
        let failed = failedPayload(plans: plans, notes: failureNotes)

        let partialSuccess = !success.updatedIDs.isEmpty && !failed.isEmpty
        let payload: AnyCodableJSON = .object([
            "tool": .string(ProductsUpdateTool.name),
            "requested_count": .int(Int64(requestedCount)),
            "updated_ids": .array(success.updatedIDs.map { .int(Int64($0)) }),
            "expanded": .object(success.expanded),
            "failed": .array(failed),
            "partial_success": .bool(partialSuccess)
        ])
        return RunReceipt(payload: payload, outcomeUnknownStatuses: unknownStatuses)
    }

    private struct ExpandedPayload {
        let updatedIDs: [Int]
        let expanded: [String: AnyCodableJSON]
    }

    private static func expandedPayload(plans: [EntryPlan],
                                        successes: Set<Int>) -> ExpandedPayload {
        var updatedIDs: [Int] = []
        var expanded: [String: AnyCodableJSON] = [:]
        for plan in plans {
            if let parent = plan.expandedParent {
                var variationIDs: [Int] = []
                for write in plan.writes where successes.contains(write.targetID) {
                    updatedIDs.append(write.targetID)
                    if write.expandedParent != nil {
                        variationIDs.append(write.targetID)
                    }
                }
                // Suppress the entry entirely when no variation write landed; an empty
                // `variations_updated` array implies expansion ran with no hits, which misleads.
                guard !variationIDs.isEmpty else { continue }
                variationIDs.sort()
                let entryPayload: [String: AnyCodableJSON] = [
                    "variations_updated": .array(variationIDs.map { .int(Int64($0)) })
                ]
                expanded[String(parent)] = .object(entryPayload)
            } else {
                for write in plan.writes where successes.contains(write.targetID) {
                    updatedIDs.append(write.targetID)
                }
            }
        }
        return ExpandedPayload(updatedIDs: updatedIDs, expanded: expanded)
    }

    private static func failedPayload(plans: [EntryPlan],
                                      notes: [(Int, String)]) -> [AnyCodableJSON] {
        var failed: [AnyCodableJSON] = []
        for plan in plans {
            for failure in plan.preDispatchFailures {
                failed.append(.object([
                    "id": .int(Int64(failure.0)),
                    "reason": .string(failure.1)
                ]))
            }
        }
        for note in notes {
            failed.append(.object([
                "id": .int(Int64(note.0)),
                "reason": .string(note.1)
            ]))
        }
        return failed
    }
}

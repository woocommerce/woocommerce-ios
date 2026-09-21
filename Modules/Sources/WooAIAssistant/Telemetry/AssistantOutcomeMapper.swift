import Foundation

enum AssistantOutcomeMapper {

    static func map(_ outcome: LoopOutcome) -> AssistantTelemetryOutcome {
        switch outcome {
        case .completed:
            return .success
        case .failed:
            return .failed
        case .stopped:
            return .cancelledByUser
        case .maxIterations:
            return .maxIterations
        }
    }
}

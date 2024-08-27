import Foundation

/// Tone of voice for AI
///
public enum AIToneVoice: String, CaseIterable {
    case casual = "Casual"
    case formal = "Formal"
    case flowery = "Flowery"
    case convincing = "Convincing"

    var description: String {
        switch self {
        case .casual:
            Localization.casual
        case .formal:
            Localization.formal
        case .flowery:
            Localization.flowery
        case .convincing:
            Localization.convincing
        }
    }

    enum Localization {
        static let casual = NSLocalizedString(
            "aiToneVoice.casual",
            value: "Casual",
            comment: "Title of Casual AI Tone"
        )
        static let formal = NSLocalizedString(
            "aiToneVoice.formal",
            value: "Formal",
            comment: "Title of Formal AI Tone"
        )
        static let flowery = NSLocalizedString(
            "aiToneVoice.flowery",
            value: "Flowery",
            comment: "Title of Flowery AI Tone"
        )
        static let convincing = NSLocalizedString(
            "aiToneVoice.convincing",
            value: "Convincing",
            comment: "Title of Convincing AI Tone"
        )
    }
}

import Foundation
import protocol WooFoundation.Analytics

/// View model for `AIToneVoiceView`.
///
final class AIToneVoiceViewModel: ObservableObject {
    let tones = AIToneVoice.allCases

    @Published var selectedTone: AIToneVoice

    private let siteID: Int64
    private let analytics: Analytics
    private let userDefaults: UserDefaults

    init(siteID: Int64,
         userDefaults: UserDefaults = .standard,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteID = siteID
        self.analytics = analytics
        self.userDefaults = userDefaults
        self.selectedTone = userDefaults.aiTone(for: siteID)
    }

    func onSelectTone(_ aiPromptTone: AIToneVoice) {
        self.selectedTone = aiPromptTone
        userDefaults.setAITone(aiPromptTone, for: siteID)
        analytics.track(event: .ProductCreationAI.aiToneSelected(aiPromptTone))
    }
}

// MARK: - AI tone helpers
extension UserDefaults {
    private enum Constants {
        static let defaultTone = AIToneVoice.casual
    }
    /// Returns AI tone for the site ID
    ///
    func aiTone(for siteID: Int64) -> AIToneVoice {
        let aiPromptTone = self[.aiPromptTone] as? [String: String]
        let idAsString = "\(siteID)"
        guard let rawValue = aiPromptTone?[idAsString],
              let tone = AIToneVoice(rawValue: rawValue) else {
            setAITone(Constants.defaultTone, for: siteID)
            return Constants.defaultTone
        }
        return tone
    }

    /// Stores the AI tone for the given site ID
    ///
    func setAITone(_ tone: AIToneVoice, for siteID: Int64) {
        let idAsString = "\(siteID)"
        if var aiPromptToneDictionary = self[.aiPromptTone] as? [String: String] {
            aiPromptToneDictionary[idAsString] = tone.rawValue
            self[.aiPromptTone] = aiPromptToneDictionary
        } else {
            self[.aiPromptTone] = [idAsString: tone.rawValue]
        }
    }
}

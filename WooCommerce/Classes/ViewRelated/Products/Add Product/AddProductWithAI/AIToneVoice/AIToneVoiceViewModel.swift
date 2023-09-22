import Foundation

public enum AIToneVoice: String, CaseIterable {
    case casual = "Casual"
    case formal = "Formal"
    case flowery = "Flowery"
    case convincing = "Convincing"
}

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
        if let storedPrompt = userDefaults.aiTone(for: siteID) {
            self.selectedTone = storedPrompt
        } else {
            self.selectedTone = .casual
            userDefaults.setAITone(.casual, for: siteID)
        }
    }

    func onSelectTone(_ aiPromptTone: AIToneVoice) {
        self.selectedTone = aiPromptTone
        userDefaults.setAITone(aiPromptTone, for: siteID)
    }
}

// MARK: - AI tone helpers
extension UserDefaults {
    /// Returns AI tone for the site ID
    ///
    func aiTone(for siteID: Int64) -> AIToneVoice? {
        let aiPromptTone = self[.aiPromptTone] as? [String: String]
        let idAsString = "\(siteID)"
        guard let rawValue = aiPromptTone?[idAsString],
              let tone = AIToneVoice(rawValue: rawValue) else {
            return nil
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

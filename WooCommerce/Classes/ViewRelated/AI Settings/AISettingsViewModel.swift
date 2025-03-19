import SwiftUI

final class AISettingsViewModel: ObservableObject {
    @Published var apiKey: String
    @Published var selectedModel: String
    @Published var selectedProvider: String

    private let defaults: UserDefaults

    let openAIModels = [
        "gpt-4o",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]

    let anthropicModels = [
        "claude-3-haiku-20240307"
    ]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.apiKey = defaults.string(forKey: "AIProviderAPIKey") ?? ""
        self.selectedModel = defaults.string(forKey: "AIProviderModel") ?? ""
        self.selectedProvider = defaults.string(forKey: "AIProvider") ?? ""
    }

    func updateProvider(_ provider: String) {
        selectedProvider = provider
        selectedModel = provider == "OpenAI" ? openAIModels.first ?? "" : anthropicModels.first ?? ""
        saveSettings()
    }

    private func saveSettings() {
        defaults.setValue(apiKey, forKey: "AIProviderAPIKey")
        defaults.setValue(selectedModel, forKey: "AIProviderModel")
        defaults.setValue(selectedProvider, forKey: "AIProvider")
    }
}

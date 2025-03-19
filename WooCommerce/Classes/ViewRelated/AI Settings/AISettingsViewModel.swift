import SwiftUI

final class AISettingsViewModel: ObservableObject {
    @Published var apiKey: String
    @Published var selectedModel: String
    @Published var selectedProvider: String
    @Published var isEditingApiKey: Bool

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
        self.isEditingApiKey = false
    }

    func onAppear() {
        isEditingApiKey = apiKey.isEmpty
        debug_getSiteDetails()
        debug_logSettings()
    }

    func updateProvider(_ provider: String) {
        selectedProvider = provider
        selectedModel = provider == "OpenAI" ? openAIModels.first ?? "" : anthropicModels.first ?? ""
        saveSettings()
    }

    func clearApiKey() {
        apiKey = ""
        debug_logSettings()
    }

    func toggleEditing() {
        if isEditingApiKey {
            saveSettings()
        }
        isEditingApiKey.toggle()
        debug_logSettings()
    }

    private func saveSettings() {
        defaults.setValue(apiKey, forKey: "AIProviderAPIKey")
        defaults.setValue(selectedModel, forKey: "AIProviderModel")
        defaults.setValue(selectedProvider, forKey: "AIProvider")
    }
}

// MARK: - Debug helpers
private extension AISettingsViewModel {
    func debug_getSiteDetails() {
        guard let site = ServiceLocator.stores.sessionManager.defaultSite else {
            return
        }
        debugPrint("""
                🍍
                - isAIAssistantFeatureActive : \(site.isAIAssistantFeatureActive)
                - isJetpackThePluginInstalled : \(site.isJetpackThePluginInstalled)
                - isJetpackConnected : \(site.isJetpackConnected)
                - isWooCommerceActive : \(site.isWooCommerceActive)
                - isWordPressComStore : \(site.isWordPressComStore)
                """)
    }

    private func debug_logSettings() {
        let maskedApiKey: String = {
            if apiKey.count > 8 {
                let start = apiKey.prefix(4)
                let end = apiKey.suffix(4)
                return "\(start)****\(end)"
            } else {
                return "****"
            }
        }()

        print("AIProviderApiKey: \(maskedApiKey)")
        print("selectedModel: \(selectedModel)")
        print("selectedProvider: \(selectedProvider)")
        print("isEditingApiKey: \(isEditingApiKey)")
    }
}

import SwiftUI
import KeychainAccess

final class AISettingsViewModel: ObservableObject {
    private var keychain = Keychain(service: WooConstants.keychainServiceName)

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
        self.apiKey = Keychain(service: WooConstants.keychainServiceName).aiProviderAPIKey ?? ""
        self.selectedModel = defaults.string(forKey: "AIProviderModel") ?? ""
        self.selectedProvider = defaults.string(forKey: "AIProvider") ?? ""
        self.isEditingApiKey = false
    }

    func onAppear() {
        isEditingApiKey = apiKey.isEmpty
    }

    func updateProvider(_ provider: String) {
        selectedProvider = provider
        selectedModel = provider == "OpenAI" ? openAIModels.first ?? "" : anthropicModels.first ?? ""
        saveSettings()
    }

    func clearApiKey() {
        apiKey = ""
        keychain.aiProviderAPIKey = nil
    }

    func toggleEditing() {
        if isEditingApiKey {
            saveSettings()
        }
        isEditingApiKey.toggle()
    }

    private func saveSettings() {
        keychain.aiProviderAPIKey = apiKey
        defaults.setValue(selectedModel, forKey: "AIProviderModel")
        defaults.setValue(selectedProvider, forKey: "AIProvider")
    }
}

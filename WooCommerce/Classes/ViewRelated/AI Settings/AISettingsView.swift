import SwiftUI

struct AISettingsView: View {
    @State private var AIProviderApiKey: String = UserDefaults.standard.string(forKey: "AIProviderAPIKey") ?? ""
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "AIProviderModel") ?? "gpt-4o"
    @State private var selectedProvider: String = UserDefaults.standard.string(forKey: "AIProvider") ?? "OpenAI"

    let openAIModels = [
        "gpt-4o",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]
    let anthropicModels = [
        "claude-3-haiku-20240307"
    ]

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Provider")
                    Picker("Select Provider", selection: $selectedProvider) {
                        Text("OpenAI").tag("OpenAI")
                        Text("Anthropic").tag("Anthropic")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedProvider) { _ in
                        selectedModel = selectedProvider == "OpenAI" ? openAIModels.first ?? "" : anthropicModels.first ?? ""
                        UserDefaults.standard.setValue(selectedModel, forKey: "AIProviderModel")
                        UserDefaults.standard.setValue(selectedProvider, forKey: "AIProvider")
                    }
                }

                HStack {
                    Text("Models")
                    Picker("Select Model", selection: $selectedModel) {
                        ForEach(selectedProvider == "OpenAI" ? openAIModels : anthropicModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Divider()
                HStack {
                    TextField("Enter API Key", text: $AIProviderApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))

                    Button(action: {
                        UserDefaults.standard.setValue(AIProviderApiKey, forKey: "AIProviderAPIKey")
                        UserDefaults.standard.setValue(selectedModel, forKey: "AIProviderModel")
                        UserDefaults.standard.setValue(selectedProvider, forKey: "AIProvider")
                    }, label: { Text("Save") })
                }
                Text("Enter your API key to use AI generation at public API costs.")
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("AI Settings")
        .onAppear {
            getSiteDetails()
        }
    }

    func getSiteDetails() {
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
}

#Preview {
    AISettingsView()
}

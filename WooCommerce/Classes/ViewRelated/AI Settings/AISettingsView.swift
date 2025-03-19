import SwiftUI
import Yosemite

struct AISettingsView: View {
    @State private var AIProviderApiKey: String = UserDefaults.standard.string(forKey: "AIProviderAPIKey") ?? ""
    @State private var selectedModel: String = UserDefaults.standard.string(forKey: "AIProviderModel") ?? ""
    @State private var selectedProvider: String = UserDefaults.standard.string(forKey: "AIProvider") ?? ""
    @State private var isEditingApiKey: Bool = false

    let openAIModels = [
        "gpt-4o",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]
    let anthropicModels = [
        "claude-3-haiku-20240307"
    ]
    private let viewModel: AISettingsViewModel
    
    init(viewModel: AISettingsViewModel) {
        self.viewModel = viewModel
    }

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
                        logSettings()
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
                    .onChange(of: selectedModel) { _ in
                        logSettings()
                    }
                }

                Divider()
                HStack {
                    TextField("Enter API Key", text: $AIProviderApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: isEditingApiKey))
                        .foregroundColor(isEditingApiKey ? .primary : .gray)
                        .disabled(!isEditingApiKey)

                    if !AIProviderApiKey.isEmpty {
                        Button(action: {
                            AIProviderApiKey = ""
                            logSettings()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }

                    Button(action: {
                        if isEditingApiKey {
                            UserDefaults.standard.setValue(AIProviderApiKey, forKey: "AIProviderAPIKey")
                            UserDefaults.standard.setValue(selectedModel, forKey: "AIProviderModel")
                            UserDefaults.standard.setValue(selectedProvider, forKey: "AIProvider")
                            isEditingApiKey = false
                        } else {
                            isEditingApiKey = true
                        }
                        logSettings()
                    }, label: { Text(isEditingApiKey ? "Save" : "Edit") })
                }
                Text("Enter your API key to use AI generation at public API costs.")
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("AI Settings")
        .onAppear {
            if !AIProviderApiKey.isEmpty {
                isEditingApiKey = false
            } else {
                isEditingApiKey = true
            }
            logSettings()
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

    private func logSettings() {
        // TODO: Analytics
        let maskedApiKey: String = {
            if AIProviderApiKey.count > 8 {
                let start = AIProviderApiKey.prefix(4)
                let end = AIProviderApiKey.suffix(4)
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

#Preview {
    AISettingsView(viewModel: AISettingsViewModel())
}

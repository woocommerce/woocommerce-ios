import SwiftUI
import KeychainAccess

@Observable final class AISettingsViewModel {
    var keychain = Keychain(service: WooConstants.keychainServiceName)

    var usesJetpackAsDefaultAIProviderSource: Bool = false
    var isEditingApiKey: Bool = false
    var apiKey: String = ""
    var selectedProvider: String = "OpenAI"
    var selectedModel: String = "gpt-4"

    func toggleEditing() {
        if isEditingApiKey {
            saveSettings()
        }
        isEditingApiKey.toggle()
    }

    func updateProvider(_ provider: String) {
        // TODO
        // Switches between AI providers
    }

    func clearAPIKey() {
        apiKey = ""
        keychain.merchantAIProviderKey = nil
    }

    private func saveSettings() {
        keychain.merchantAIProviderKey = apiKey
    }
}

struct AISettingsView: View {
    @State private var viewModel: AISettingsViewModel

    init(viewModel: AISettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // Disable AI settings when the site already uses Jetpack as the default AI source
    private var aiSettingsDisabled: Bool {
        viewModel.usesJetpackAsDefaultAIProviderSource
    }

    private var fieldOpacity: Double {
        aiSettingsDisabled ? 0.5 : 1.0
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        VStack(alignment: .leading) {
            if aiSettingsDisabled {
                JetpackAsAIDefaultSourceBannerView()
            }

            HStack {
                TextField(
                    Localization.enterAPIKey,
                    text: Binding(
                        get: { viewModel.isEditingApiKey ? viewModel.apiKey : "**********" },
                        set: { newValue in
                            if viewModel.isEditingApiKey { viewModel.apiKey = newValue }
                        }
                    )
                )
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(.primary)
                .privacySensitive()

                if viewModel.isEditingApiKey, !viewModel.apiKey.isEmpty {
                    Button(action: viewModel.clearAPIKey) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }

                Button(action: viewModel.toggleEditing) {
                    Text(viewModel.isEditingApiKey ? Localization.save : Localization.edit)
                }
                .disabled(aiSettingsDisabled)
                .opacity(fieldOpacity)
            }

            Text(Localization.apiKeyDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text(Localization.aiProvider)
                    .foregroundColor(.secondary)
                Picker(Localization.selectProvider, selection: $viewModel.selectedProvider) {
                    // TODO
                    Text(Localization.openAI).tag(Localization.openAI)
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: viewModel.selectedProvider) { _, newValue in
                    viewModel.updateProvider(newValue)
                }
                .disabled(aiSettingsDisabled)
                .opacity(fieldOpacity)

                if viewModel.usesJetpackAsDefaultAIProviderSource {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                }
            }
            HStack {
                Text(Localization.models)
                    .foregroundColor(.secondary)
                Picker(Localization.selectModel, selection: $viewModel.selectedModel) {
                    // TODO
                    Text(viewModel.selectedModel).tag(viewModel.selectedModel)
                }
                .pickerStyle(MenuPickerStyle())
                .disabled(aiSettingsDisabled)
                .opacity(fieldOpacity)

                if aiSettingsDisabled {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(Localization.apiKeyDisclaimer)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .navigationTitle(Localization.navigationTitle)
    }
}

private extension AISettingsView {
    @ViewBuilder private func JetpackAsAIDefaultSourceBannerView() -> some View {
        Text(Localization.builtInAIEnabled)
            .font(.callout)
            .foregroundColor(.secondary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cornerRadius)
                    .stroke(Color(.gray), lineWidth: 1)
            )
    }
}

private extension AISettingsView {
    enum Layout {
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "aiSettings.navigationTitle",
            value: "AI Settings",
            comment: "Navigation title for the AI Settings screen"
        )

        static let builtInAIEnabled = NSLocalizedString(
            "aiSettings.builtInAIEnabled",
            value: "AI capabilities are already enabled for this site.",
            comment: "Message displayed when built-in AI feature is already enabled."
        )

        static let enterAPIKey = NSLocalizedString(
            "aiSettings.enterAPIKey",
            value: "Enter API Key",
            comment: "Placeholder text for the API key input field"
        )

        static let apiKeyDescription = NSLocalizedString(
             "aiSettings.apiKeyDescription",
             value: "Enter your API key to use AI generation at public API costs.",
             comment: "Description text explaining the purpose of the API key"
         )

        static let apiKeyDisclaimer = NSLocalizedString(
            "aiSettings.apiKeyDisclaimer",
            value: "API keys open up access to potentially sensitive information. Do not share your API key with others or expose them.",
            comment: "Warning message about keeping API keys secure"
        )

        static let aiProvider = NSLocalizedString(
            "aiSettings.aiProvider",
            value: "Provider",
            comment: "Label for the AI provider selection in AI settings"
        )

        static let selectProvider = NSLocalizedString(
            "aiSettings.selectProvider",
            value: "Select Provider",
            comment: "Accessibility label for the AI provider picker"
        )

        static let openAI = NSLocalizedString(
             "aiSettings.openAI",
             value: "OpenAI",
             comment: "Label for OpenAI provider option"
         )

        static let models = NSLocalizedString(
            "aiSettings.models",
            value: "Models",
            comment: "Label for the AI models selection"
        )

        static let selectModel = NSLocalizedString(
            "aiSettings.selectModel",
            value: "Select Model",
            comment: "Accessibility label for the AI model picker"
        )

        static let edit = NSLocalizedString(
            "aiSettings.edit",
            value: "Edit",
            comment: "Button title to edit API key"
        )

        static let save = NSLocalizedString(
            "aiSettings.save",
            value: "Save",
            comment: "Button title to save API key"
        )
    }
}

#Preview {
    AISettingsView(viewModel: AISettingsViewModel())
}

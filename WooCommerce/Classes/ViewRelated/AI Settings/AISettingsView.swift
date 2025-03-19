import SwiftUI
import Yosemite

struct AISettingsView: View {
    @ObservedObject private var viewModel: AISettingsViewModel

    init(viewModel: AISettingsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text(Localization.aiProvider)
                    Picker(Localization.selectProvider, selection: $viewModel.selectedProvider) {
                        Text(Localization.openAI).tag("OpenAI")
                        Text(Localization.anthropic).tag("Anthropic")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.selectedProvider) { newValue in
                        viewModel.updateProvider(newValue)
                    }
                }

                HStack {
                    Text(Localization.models)
                    Picker(Localization.selectModel, selection: $viewModel.selectedModel) {
                        ForEach(viewModel.selectedProvider == "OpenAI" ? viewModel.openAIModels : viewModel.anthropicModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Divider()
                HStack {
                    TextField(Localization.enterAPIKey, text: $viewModel.apiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: viewModel.isEditingApiKey))
                        .foregroundColor(viewModel.isEditingApiKey ? .primary : .gray)
                        .disabled(!viewModel.isEditingApiKey)

                    if !viewModel.apiKey.isEmpty {
                        Button(action: viewModel.clearApiKey) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }

                    Button(action: viewModel.toggleEditing) {
                        Text(viewModel.isEditingApiKey ? Localization.save : Localization.edit)
                    }
                }
                Text(Localization.apiKeyDescription)
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle(Localization.navigationTitle)
        .onAppear {
            viewModel.onAppear()
        }
    }
}

private extension AISettingsView {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "aiSettings.navigationTitle",
            value: "AI Settings",
            comment: "Navigation title for the AI Settings screen"
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

        static let anthropic = NSLocalizedString(
            "aiSettings.anthropic",
            value: "Anthropic",
            comment: "Label for Anthropic provider option"
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

        static let enterAPIKey = NSLocalizedString(
            "aiSettings.enterAPIKey",
            value: "Enter API Key",
            comment: "Placeholder text for the API key input field"
        )

        static let save = NSLocalizedString(
            "aiSettings.save",
            value: "Save",
            comment: "Button title to save API key"
        )

        static let edit = NSLocalizedString(
            "aiSettings.edit",
            value: "Edit",
            comment: "Button title to edit API key"
        )

        static let apiKeyDescription = NSLocalizedString(
            "aiSettings.apiKeyDescription",
            value: "Enter your API key to use AI generation at public API costs.",
            comment: "Description text explaining the purpose of the API key"
        )
    }
}

#Preview {
    AISettingsView(viewModel: AISettingsViewModel())
}

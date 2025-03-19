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
                    Text("Provider")
                    Picker("Select Provider", selection: $viewModel.selectedProvider) {
                        Text("OpenAI").tag("OpenAI")
                        Text("Anthropic").tag("Anthropic")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.selectedProvider) { newValue in
                        viewModel.updateProvider(newValue)
                    }
                }

                HStack {
                    Text("Models")
                    Picker("Select Model", selection: $viewModel.selectedModel) {
                        ForEach(viewModel.selectedProvider == "OpenAI" ? viewModel.openAIModels : viewModel.anthropicModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Divider()
                HStack {
                    TextField("Enter API Key", text: $viewModel.apiKey)
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
                        Text(viewModel.isEditingApiKey ? "Save" : "Edit")
                    }
                }
                Text("Enter your API key to use AI generation at public API costs.")
                    .font(.caption)
            }
        }
        .padding()
        .navigationTitle("AI Settings")
        .onAppear {
            viewModel.onAppear()
        }
    }
}

#Preview {
    AISettingsView(viewModel: AISettingsViewModel())
}

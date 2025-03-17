import SwiftUI

struct AISettingsView: View {
    @State private var openAIApiKey: String = UserDefaults.standard.string(forKey: "OpenAIApiKey") ?? ""

    var body: some View {
        ScrollView {
            VStack {
                Text("Models")
                // TODO:
                Text("✅ gpt-4o")
                Text("◽️ claude-3.5-sonnet")
                Divider()

                // OpenAI
                HStack {
                    Toggle("OpenAI API key", isOn: .constant(true))
                }
                HStack {
                    TextField("Enter API Key", text: $openAIApiKey)
                        .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))

                    Button(action: {
                        UserDefaults.standard.setValue(openAIApiKey, forKey: "OpenAIApiKey")
                    }, label: { Text("Save") })
                }
                Text("Enter your OpenAI key to use AI generation at public API costs.")
                    .font(.caption)

                // Anthropic
                HStack {
                    Toggle("Anthropic API key", isOn: .constant(true))
                }
                HStack {
                    TextField(text: .constant("*****"), label: {
                        EmptyView()
                    })
                    Button(action: {
                        // TODO: not implemented
                    }, label: { Text("Save") } )
                }
                Text("Enter your Anthropic key to use AI generation at public API costs. When used, this key will be used for all 'claude-' models.")
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

import XCTest
@testable import WooCommerce

final class AISettingsViewModelTests: XCTestCase {
    var sut: AISettingsViewModel!
    var defaults: UserDefaults!
    let suiteName = #file

    private let testAIProvider = "test-ai-model"
    private let testAIModel = "test-ai-provider"

    let expectedOpenAIModels = [
        "gpt-4o",
        "gpt-4-turbo",
        "gpt-3.5-turbo"
    ]

    let expectedAnthropicModels = [
        "claude-3-haiku-20240307"
    ]

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
        sut = AISettingsViewModel(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        sut = nil
        super.tearDown()
    }

    func test_sut_when_init_then_loads_values_from_userdefaults() {
        // Given
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail()
        }
        defaults.set(testAIModel, forKey: "AIProviderModel")
        defaults.set(testAIProvider, forKey: "AIProvider")

        // When
        sut = AISettingsViewModel(defaults: defaults)

        // Then
        XCTAssertEqual(sut.selectedModel, testAIModel)
        XCTAssertEqual(sut.selectedProvider, testAIProvider)
    }

    func test_init_should_use_empty_values_when_userdefaults_is_empty() {
        XCTAssertEqual(sut.selectedModel, "")
        XCTAssertEqual(sut.selectedProvider, "")
    }

    func test_sut_when_init_then_has_correct_openai_models() {
        XCTAssertEqual(sut.openAIModels, expectedOpenAIModels)
    }

    func test_sut_when_init_then_has_correct_anthropic_models() {
        XCTAssertEqual(sut.anthropicModels, expectedAnthropicModels)
    }

    func test_sut_when_update_provider_to_openai_then_selects_first_openai_model_and_saves() {
        // When
        sut.updateProvider("OpenAI")

        // Then
        XCTAssertEqual(sut.selectedProvider, "OpenAI")
        XCTAssertEqual(sut.selectedModel, expectedOpenAIModels.first)

        // Verify that is saved to UserDefaults
        XCTAssertEqual(defaults.string(forKey: "AIProvider"), "OpenAI")
        XCTAssertEqual(defaults.string(forKey: "AIProviderModel"), expectedOpenAIModels.first)
    }

    func test_sut_when_update_provider_to_anthropic_then_selects_first_anthropic_model_and_saves() {
        // When
        sut.updateProvider("Anthropic")

        // Then
        XCTAssertEqual(sut.selectedProvider, "Anthropic")
        XCTAssertEqual(sut.selectedModel, expectedAnthropicModels.first)

        // And verify saved to defaults
        XCTAssertEqual(defaults.string(forKey: "AIProvider"), "Anthropic")
        XCTAssertEqual(defaults.string(forKey: "AIProviderModel"), expectedAnthropicModels.first)
    }

    func test_sut_when_update_provider_then_persists_all_values_to_userdefaults() {
        // Given
        sut.apiKey = "new-api-key"

        // When
        sut.updateProvider("OpenAI")

        // Then
        XCTAssertEqual(defaults.string(forKey: "AIProviderModel"), expectedOpenAIModels.first)
        XCTAssertEqual(defaults.string(forKey: "AIProvider"), "OpenAI")
    }

    func test_sut_when_onAppear_with_empty_apiKey_then_enables_editing() {
        // Given
        sut.apiKey = ""
        sut.isEditingApiKey = false

        // When
        sut.onAppear()

        // Then
        XCTAssertTrue(sut.isEditingApiKey)
    }

    func test_sut_when_onAppear_with_apiKey_then_disables_editing() {
        // Given
        sut.apiKey = "some-key"
        sut.isEditingApiKey = true

        // When
        sut.onAppear()

        // Then
        XCTAssertFalse(sut.isEditingApiKey)
    }

    func test_sut_when_clearApiKey_then_empties_apiKey() {
        // Given
        sut.apiKey = "some-key"

        // When
        sut.clearApiKey()

        // Then
        XCTAssertTrue(sut.apiKey.isEmpty)
    }

    func test_sut_when_toggleEditing_then_toggles_editing_state() {
        // Given
        sut.isEditingApiKey = false

        // When
        sut.toggleEditing()

        // Then
        XCTAssertTrue(sut.isEditingApiKey)
    }

    func test_sut_when_togglEediting_from_editing_then_saves_settings() {
        // Given
        sut.isEditingApiKey = true
        sut.apiKey = "new-key"
        sut.selectedModel = "test-model"
        sut.selectedProvider = "test-provider"

        // When
        sut.toggleEditing()

        // Then
        XCTAssertFalse(sut.isEditingApiKey)
        XCTAssertEqual(defaults.string(forKey: "AIProviderModel"), "test-model")
        XCTAssertEqual(defaults.string(forKey: "AIProvider"), "test-provider")
    }
}

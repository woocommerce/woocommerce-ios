import XCTest
@testable import Networking

final class AIRequestPromptsTests: XCTestCase {

    // MARK: - Basic Prompt Instructions Tests

    func test_identifyLanguage_formatsCorrectly() {
        // Given
        let testString = "Hello world, this is a test string"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.identifyLanguage, testString)

        // Then
        let expectedPrompt = """
        What is the ISO language code of the language used in the below text?
        Do not include any explanations and only provide the ISO language code in your response.
        Text: ```\(testString)
        """

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_inputComponents_formatsCorrectly() {
        // Given
        let keywords = "smartphone, technology, mobile"
        let tone = "professional"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.inputComponents, keywords, tone)

        // Then
        // swiftlint:disable line_length
        let expectedPrompt = """
        You are a WooCommerce SEO and marketing expert, perform in-depth research about the product using the provided name, keywords, and tone, and give your response in the below JSON format.
        keywords: ```\(keywords)```
        tone: ```\(tone)```
        """
        // swiftlint:enable line_length

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_jsonFormatInstructions_formatsCorrectly() {
        // Given
        let jsonSchema = """
        {
          "name": "Product name here",
          "description": "Product description here"
        }
        """

        // When
        let formattedPrompt = String(format: AIRequestPrompts.jsonFormatInstructions, jsonSchema)

        // Then
        let expectedPrompt = """
        Your response should be in JSON format and don't send anything extra. Don't include the word JSON in your response:
        \(jsonSchema)
        """

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - Product Generation Tests

    func test_productNameTemplate_formatsCorrectly() {
        // Given
        let productName = "iPhone 15 Pro"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.productNameTemplate, productName)

        // Then
        let expectedPrompt = "name: ```\(productName)```"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - Tags Tests

    func test_defaultTagsPrompt_returnsCorrectString() {
        // When
        let prompt = AIRequestPrompts.defaultTagsPrompt

        // Then
        let expectedPrompt = "Suggest an array of the best matching tags for this product."

        XCTAssertEqual(prompt, expectedPrompt)
    }

    func test_existingTagsPrompt_formatsCorrectly() {
        // Given
        let existingTags = "electronics, smartphone, apple, premium"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.existingTagsPrompt, existingTags)

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "Given the list of available tags ```\(existingTags)```, suggest an array of the best matching tags for this product. You can suggest new tags as well."

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - Categories Tests

    func test_defaultCategoriesPrompt_returnsCorrectString() {
        // When
        let prompt = AIRequestPrompts.defaultCategoriesPrompt

        // Then
        let expectedPrompt = "Suggest an array of the best matching categories for this product."

        XCTAssertEqual(prompt, expectedPrompt)
    }

    func test_existingCategoriesPrompt_formatsCorrectly() {
        // Given
        let existingCategories = "Electronics, Mobile Phones, Accessories"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.existingCategoriesPrompt, existingCategories)

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "Given the list of available categories ```\(existingCategories)```, suggest an array of the best matching categories for this product. You can suggest new categories as well."

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - Shipping Tests

    func test_weightPrompt_formatsCorrectly() {
        // Given
        let weightUnit = "kg"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.weightPrompt, weightUnit)

        // Then
        let expectedPrompt = "Guess and provide only the number in \(weightUnit)"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_lengthPrompt_formatsCorrectly() {
        // Given
        let dimensionUnit = "cm"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.lengthPrompt, dimensionUnit)

        // Then
        let expectedPrompt = "Guess and provide only the number in \(dimensionUnit)"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_widthPrompt_formatsCorrectly() {
        // Given
        let dimensionUnit = "cm"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.widthPrompt, dimensionUnit)

        // Then
        let expectedPrompt = "Guess and provide only the number in \(dimensionUnit)"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_heightPrompt_formatsCorrectly() {
        // Given
        let dimensionUnit = "cm"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.heightPrompt, dimensionUnit)

        // Then
        let expectedPrompt = "Guess and provide only the number in \(dimensionUnit)"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - JSON Response Format Tests

    func test_namesFormat_formatsCorrectly() {
        // Given
        let language = "en"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.namesFormat, language)

        // Then
        let expectedPrompt = "An array of strings, containing three different names of the product, written in the language with ISO code ```\(language)```"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_descriptionsFormat_formatsCorrectly() {
        // Given
        let tone = "professional"
        let language = "en"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.descriptionsFormat, tone, language)

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "An array of strings, each containing three different product descriptions of around 100 words long each in a ```\(tone)``` tone, written in the language with ISO code ```\(language)```"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_shortDescriptionsFormat_formatsCorrectly() {
        // Given
        let tone = "casual"
        let language = "es"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.shortDescriptionsFormat, tone, language)

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "An array of strings, each containing three different short descriptions of the product in a ```\(tone)``` tone, written in the language with ISO code ```\(language)```"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    func test_virtualFormat_returnsCorrectString() {
        // When
        let prompt = AIRequestPrompts.virtualFormat

        // Then
        let expectedPrompt = "A boolean value that shows whether the product is virtual or physical"

        XCTAssertEqual(prompt, expectedPrompt)
    }

    func test_priceFormat_formatsCorrectly() {
        // Given
        let currencySymbol = "$"

        // When
        let formattedPrompt = String(format: AIRequestPrompts.priceFormat, currencySymbol)

        // Then
        let expectedPrompt = "Guess the price in \(currencySymbol), do not include the currency symbol, only provide the price as a number"

        XCTAssertEqual(formattedPrompt, expectedPrompt)
    }

    // MARK: - Integration Tests (as used in GenerativeContentRemote)

    func test_generateAIProduct_tagsPromptIntegration_withEmptyTags() {
        // Given
        let tags: [String] = []

        // When
        let tagsPrompt: String = {
            guard !tags.isEmpty else {
                return AIRequestPrompts.defaultTagsPrompt
            }
            return String(format: AIRequestPrompts.existingTagsPrompt, tags.joined(separator: ", "))
        }()

        // Then
        XCTAssertEqual(tagsPrompt, "Suggest an array of the best matching tags for this product.")
    }

    func test_generateAIProduct_tagsPromptIntegration_withExistingTags() {
        // Given
        let tags = ["electronics", "smartphone", "premium"]

        // When
        let tagsPrompt: String = {
            guard !tags.isEmpty else {
                return AIRequestPrompts.defaultTagsPrompt
            }
            return String(format: AIRequestPrompts.existingTagsPrompt, tags.joined(separator: ", "))
        }()

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "Given the list of available tags ```electronics, smartphone, premium```, suggest an array of the best matching tags for this product. You can suggest new tags as well."
        XCTAssertEqual(tagsPrompt, expectedPrompt)
    }

    func test_generateAIProduct_categoriesPromptIntegration_withEmptyCategories() {
        // Given
        let categories: [String] = []

        // When
        let categoriesPrompt: String = {
            guard !categories.isEmpty else {
                return AIRequestPrompts.defaultCategoriesPrompt
            }
            return String(format: AIRequestPrompts.existingCategoriesPrompt, categories.joined(separator: ", "))
        }()

        // Then
        XCTAssertEqual(categoriesPrompt, "Suggest an array of the best matching categories for this product.")
    }

    func test_generateAIProduct_categoriesPromptIntegration_withExistingCategories() {
        // Given
        let categories = ["Electronics", "Mobile Phones", "Apple"]

        // When
        let categoriesPrompt: String = {
            guard !categories.isEmpty else {
                return AIRequestPrompts.defaultCategoriesPrompt
            }
            return String(format: AIRequestPrompts.existingCategoriesPrompt, categories.joined(separator: ", "))
        }()

        // Then
        // swiftlint:disable:next line_length
        let expectedPrompt = "Given the list of available categories ```Electronics, Mobile Phones, Apple```, suggest an array of the best matching categories for this product. You can suggest new categories as well."
        XCTAssertEqual(categoriesPrompt, expectedPrompt)
    }

    func test_generateAIProduct_shippingPromptIntegration() {
        // Given
        let weightUnit: String? = "kg"
        let dimensionUnit: String? = "cm"

        // When
        let shippingPrompt = {
            var dict = [String: String]()
            if let weightUnit = weightUnit {
                dict["weight"] = String(format: AIRequestPrompts.weightPrompt, weightUnit)
            }

            if let dimensionUnit = dimensionUnit {
                dict["length"] = String(format: AIRequestPrompts.lengthPrompt, dimensionUnit)
                dict["width"] = String(format: AIRequestPrompts.widthPrompt, dimensionUnit)
                dict["height"] = String(format: AIRequestPrompts.heightPrompt, dimensionUnit)
            }
            return dict
        }()

        // Then
        let expectedDict = [
            "weight": "Guess and provide only the number in kg",
            "length": "Guess and provide only the number in cm",
            "width": "Guess and provide only the number in cm",
            "height": "Guess and provide only the number in cm"
        ]

        XCTAssertEqual(shippingPrompt, expectedDict)
    }

    func test_generateAIProduct_fullJSONResponseFormatDictIntegration() {
        // Given
        let language = "en"
        let tone = "professional"
        let currencySymbol = "$"
        let tagsPrompt = AIRequestPrompts.defaultTagsPrompt
        let categoriesPrompt = AIRequestPrompts.defaultCategoriesPrompt
        let shippingPrompt = [
            "weight": String(format: AIRequestPrompts.weightPrompt, "kg"),
            "length": String(format: AIRequestPrompts.lengthPrompt, "cm")
        ]

        // When
        let jsonResponseFormatDict: [String: Any] = [
            "names": String(format: AIRequestPrompts.namesFormat, language),
            "descriptions": String(format: AIRequestPrompts.descriptionsFormat, tone, language),
            "short_descriptions": String(format: AIRequestPrompts.shortDescriptionsFormat, tone, language),
            "virtual": AIRequestPrompts.virtualFormat,
            "shipping": shippingPrompt,
            "price": String(format: AIRequestPrompts.priceFormat, currencySymbol),
            "tags": tagsPrompt,
            "categories": categoriesPrompt
        ]

        // Then
        // swiftlint:disable:next line_length
        XCTAssertEqual(jsonResponseFormatDict["names"] as? String, "An array of strings, containing three different names of the product, written in the language with ISO code ```en```")
        // swiftlint:disable:next line_length
        XCTAssertEqual(jsonResponseFormatDict["descriptions"] as? String, "An array of strings, each containing three different product descriptions of around 100 words long each in a ```professional``` tone, written in the language with ISO code ```en```")
        // swiftlint:disable:next line_length
        XCTAssertEqual(jsonResponseFormatDict["short_descriptions"] as? String, "An array of strings, each containing three different short descriptions of the product in a ```professional``` tone, written in the language with ISO code ```en```")
        XCTAssertEqual(jsonResponseFormatDict["virtual"] as? String, "A boolean value that shows whether the product is virtual or physical")
        XCTAssertEqual(jsonResponseFormatDict["price"] as? String, "Guess the price in $, do not include the currency symbol, only provide the price as a number")
        XCTAssertEqual(jsonResponseFormatDict["tags"] as? String, "Suggest an array of the best matching tags for this product.")
        XCTAssertEqual(jsonResponseFormatDict["categories"] as? String, "Suggest an array of the best matching categories for this product.")

        // Verify shipping dictionary
        let actualShippingDict = jsonResponseFormatDict["shipping"] as? [String: String]
        let expectedShippingDict = [
            "weight": "Guess and provide only the number in kg",
            "length": "Guess and provide only the number in cm"
        ]
        XCTAssertEqual(actualShippingDict, expectedShippingDict)
    }
}

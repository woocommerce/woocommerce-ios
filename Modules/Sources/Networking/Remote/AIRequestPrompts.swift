
struct AIRequestPrompts {
    // Prompt instructions
    static let identifyLanguage = [
        "What is the ISO language code of the language used in the below text?",
        "Do not include any explanations and only provide the ISO language code in your response.",
        "Text: ```%@"
    ].joined(separator: "\n")

    static let inputComponents = [
        "You are a WooCommerce SEO and marketing expert, perform in-depth research about the product " +
        "using the provided name, keywords, and tone, and give your response in the below JSON format.",
        "keywords: ```%@```",
        "tone: ```%@```"
    ].joined(separator: "\n")

    static let jsonFormatInstructions =
    "Your response should be in JSON format and don't send anything extra. " +
    "Don't include the word JSON in your response:" +
    "\n%@"

    // Product Generation
    static let productNameTemplate = "name: ```%@```"

    // Tags
    static let defaultTagsPrompt = "Suggest an array of the best matching tags for this product."
    static let existingTagsPrompt =
    "Given the list of available tags ```%@```, " +
    "suggest an array of the best matching tags for this product. You can suggest new tags as well."

    // Categories
    static let defaultCategoriesPrompt = "Suggest an array of the best matching categories for this product."
    static let existingCategoriesPrompt =
    "Given the list of available categories ```%@```, " +
    "suggest an array of the best matching categories for this product. You can suggest new categories as well."

    // Shipping
    static let weightPrompt = "Guess and provide only the number in %@"
    static let lengthPrompt = "Guess and provide only the number in %@"
    static let widthPrompt = "Guess and provide only the number in %@"
    static let heightPrompt = "Guess and provide only the number in %@"

    //JSON Response Format
    static let namesFormat = "An array of strings, containing three different names of the product, written in the language with ISO code ```%@```"
    static let descriptionsFormat =
    "An array of strings, each containing three different product descriptions of around 100 words long each in a ```%@``` tone, " +
    "written in the language with ISO code ```%@```"
    static let shortDescriptionsFormat =
    "An array of strings, each containing three different short descriptions of the product in a ```%@``` tone, " +
    "written in the language with ISO code ```%@```"
    static let virtualFormat = "A boolean value that shows whether the product is virtual or physical"
    static let priceFormat =
    "Guess the price in %@, do not include the currency symbol, " +
    "only provide the price as a number"
}

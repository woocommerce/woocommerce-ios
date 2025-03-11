/// Mapper: WordPressMedia
///
public struct WordPressMediaMapper: Mapper {
    /// Public initializer
    public init() {}

    /// (Attempts) to convert data into a WordPressMedia.
    public func map(response: Data) throws -> WordPressMedia {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Constants.dateFormatterForDecoding)
        return try decoder.decode(WordPressMedia.self, from: response)
    }
}

/// Mapper: WordPressMedia List
///
public struct WordPressMediaListMapper: Mapper {
    /// Public initializer
    public init() {}

    /// (Attempts) to convert data into a WordPressMedia list.
    public func map(response: Data) throws -> [WordPressMedia] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Constants.dateFormatterForDecoding)
        return try decoder.decode([WordPressMedia].self, from: response)
    }
}

private enum Constants {
    static let dateFormatterForDecoding = DateFormatter.Defaults.dateTimeFormatter
}

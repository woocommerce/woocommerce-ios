struct ClipDropMediaMapper: Mapper {
    /// (Attempts) to convert data into a UIImage.
    func map(response: Data) throws -> UIImage {
        guard let image = UIImage(data: response) else {
            throw NSError(domain: "", code: 1)
        }
        return image
    }
}

/// Mapper: WordPressMedia
///
struct WordPressMediaMapper: Mapper {
    /// (Attempts) to convert data into a WordPressMedia.
    func map(response: Data) throws -> WordPressMedia {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Constants.dateFormatterForDecoding)
        return try decoder.decode(WordPressMedia.self, from: response)
    }
}

/// Mapper: WordPressMedia List
///
struct WordPressMediaListMapper: Mapper {
    /// (Attempts) to convert data into a WordPressMedia list.
    func map(response: Data) throws -> [WordPressMedia] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Constants.dateFormatterForDecoding)
        return try decoder.decode([WordPressMedia].self, from: response)
    }
}

private enum Constants {
    static let dateFormatterForDecoding = DateFormatter.Defaults.dateTimeFormatter
}

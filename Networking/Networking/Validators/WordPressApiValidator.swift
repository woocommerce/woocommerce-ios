struct WordPressApiValidator: ResponseDataValidator {
    /// Throws a WordPressApiError contained in a given Data Instance (if any).
    ///
    func validate(data: Data) throws {
        guard let error = try? JSONDecoder().decode(WordPressApiError.self, from: data) else {
            return
        }
        throw error
    }
}

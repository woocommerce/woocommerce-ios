import Foundation

/// Mapper for a list of `WordPressPage`.
///
struct WordPressPageListMapper: Mapper {

    func map(response: Data) throws -> [WordPressPage] {
        let decoder = JSONDecoder()
        return try decoder.decode([WordPressPage].self, from: response)
    }
}

import Foundation


/// Mapper: Ignore responses
///
struct IgnoringResponseMapper: Mapper {

    func map(response: Data) throws -> Void {
        // Do nothing, accept any type of response, including null
    }
}

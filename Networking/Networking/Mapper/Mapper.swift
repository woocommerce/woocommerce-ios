import Foundation


/// Defines a Mapping Entity that will be used to parse a Backend Response.
///
protocol Mapper {

    /// Defines the Mapping Return Type.
    ///
    associatedtype Output

    /// Maps a Backend Response into a generic entity of Type `Output`. This method *can throw* errors.
    ///
    func map(response: Data) throws -> Output
}

extension Mapper where Output: Decodable {

    func extract(from response: Data, using decoder: JSONDecoder) throws -> Output {
        if hasDataEnvelope(in: response) {
            return try decoder.decode(Envelope<Output>.self, from: response).data
        } else {
            return try decoder.decode(Output.self, from: response)
        }
    }
}

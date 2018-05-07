import Foundation


/// Defines a Mapping Entity that will be used to parse a Backend Response.
///
protocol Mapper {

    /// Defines the Mapping Return Type.
    ///
    associatedtype T

    /// Maps a Backend Response into a generic entity of Type `T`. This method *can throw* errors.
    ///
    func map(response: [String: Any]) throws -> T
}


/// Default Remote Errors
///
enum MappingError: Error {

    /// Indicates that the Backend's Response is not in the expected format.
    ///
    case unknownFormat

    /// Indicates that the value for a mandatory key is missing.
    ///
    case missingKey
}

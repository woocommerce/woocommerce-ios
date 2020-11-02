
import Foundation

/// A protocol representing `Foundation.FileManager`.
///
/// The methods in here are existing methods of `Foundation.FileManager`. Having a `protocol`
/// just allows us to use a mock `FileManager` in unit tests.
///
/// If there are methods not defined in here, feel free to add them.
///
protocol FileManagerProtocol {

    func fileExists(atPath path: String) -> Bool

    func removeItem(at URL: URL) throws

    func removeItem(atPath path: String) throws

    func createDirectory(at url: URL,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws

    func createDirectory(atPath path: String,
                         withIntermediateDirectories createIntermediates: Bool,
                         attributes: [FileAttributeKey: Any]?) throws

    func contentsOfDirectory(atPath path: String) throws -> [String]

    func moveItem(atPath srcPath: String, toPath dstPath: String) throws

    func moveItem(at srcURL: URL, to dstURL: URL) throws
}

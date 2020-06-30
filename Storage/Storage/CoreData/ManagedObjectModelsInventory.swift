
import Foundation
import class CoreData.NSManagedObjectModel

/// The main access point for finding the current Core Data ManagedObjectModel version
/// (`.xcdatamodel`/`.mom`) and all the previous model versions.
///
struct ManagedObjectModelsInventory {

    /// Errors thrown by `self.from()`
    ///
    enum IntrospectionError: Error {
        /// Failed to find the `{packageName}.momd` bundle.
        case cannotFindMomd
        /// Failed to load the `VersionInfo.plist` which should be inside the `{packageName}.momd`.
        case failedToLoadVersionInfoFile
        /// Failed to load the `NSManagedObjectModel_VersionHashes` and its contents from the
        /// `VersionInfo.plist` file.
        case failedToLoadVersionHashes
    }

    /// Represents a single `.xcdatamodel` file (or `.mom` if compiled).
    ///
    /// This is intentionally a `struct` with a single property instead of a `String` because I
    /// foresee that this will be used to contain the `NSManagedObjectModel` in the near future.
    ///
    struct ModelVersion {
        /// The name excluding the extension.
        ///
        /// For example, if the model file name is "Model 10.mom", then this would be "Model 10".
        ///
        let name: String
    }

    /// The path to the `.momd` bundle containing all the `.mom` (`ModelVersion`) files.
    ///
    let packageURL: URL

    /// The list of `ModelVersion` objects ordered by the migration sequence convention.
    ///
    let modelVersions: [ModelVersion]

    /// Create an instance of `self`. The `modelVersions` will be sorted using the migration
    /// sequence convention.
    ///
    init(packageURL: URL, modelVersions: [ModelVersion]) {
        self.packageURL = packageURL
        self.modelVersions = modelVersions.sortedByConvention()
    }

    /// Create and parse all the model versions.
    ///
    /// Parameters:
    /// - packageName: The name of the `.xcdatamodeld` bundle which contains the individual
    ///                `.xcdatamodel` (model version) files. This will also be the name
    ///                of the compiled `.momd` bundle.
    /// - bundle: The `Bundle` where the `{packageName}.momd` is expected to be in.
    ///
    static func from(packageName: String, bundle: Bundle) throws -> ManagedObjectModelsInventory {
        guard let packageURL = bundle.url(forResource: packageName, withExtension: "momd") else {
            throw IntrospectionError.cannotFindMomd
        }
        let versionInfoFileURL = self.versionInfoFileURL(from: packageURL)
        let modelVersions = try self.modelVersions(from: versionInfoFileURL)

        return ManagedObjectModelsInventory(packageURL: packageURL, modelVersions: modelVersions)
    }
}

// MARK: - Utils

private extension ManagedObjectModelsInventory {

    /// Get the expected URL of the `VersionInfo.plist` file.
    ///
    static func versionInfoFileURL(from packageURL: URL) -> URL {
        packageURL.appendingPathComponent(Constants.versionInfoPlist)
    }

    /// Get all the `ModelVersions` using the data from the `versionInfoFileURL`
    /// (`VersionInfo.plist`).
    ///
    static func modelVersions(from versionInfoFileURL: URL) throws -> [ModelVersion] {
        guard let versionInfo = NSDictionary(contentsOf: versionInfoFileURL) else {
            throw IntrospectionError.failedToLoadVersionInfoFile
        }

        // `versionHashes` looks like this in the plist:
        //
        // "NSManagedObjectModel_VersionHashes": [
        //   "Model": ["Account": "{hash}", "Order": "{hash}", ...],
        //   "Model 10": ["Account": "{hash}", "Order": "{hash}", ...],
        //   ... // and other model versions
        // ]
        //
        guard let versionHashes = versionInfo[Constants.versionHashesKey] as? NSDictionary,
            let modelNames = versionHashes.allKeys as? [String] else {
                throw IntrospectionError.failedToLoadVersionHashes
        }

        return modelNames.map {
            ModelVersion(name: $0)
        }
    }

    enum Constants {
        static let versionInfoPlist = "VersionInfo.plist"
        static let versionHashesKey = "NSManagedObjectModel_VersionHashes"
    }
}

/// MARK: - Sorting

private extension Array where Element == ManagedObjectModelsInventory.ModelVersion {
    /// Sort the `ModelVersion` based on the convention that model versions are incremented
    /// using the number in the `.xcdatamodel` name and migrations are run in sequence
    /// according to this order.
    ///
    /// Consider this array that we might receive from `modelVersions(from:)`:
    ///
    /// ```
    /// [
    ///     ModelVersion(name: "Model 10"),
    ///     ModelVersion(name: "Model 1"),
    ///     ModelVersion(name: "Model 23"),
    ///     ModelVersion(name: "Model 2"),
    ///     ModelVersion(name: "Model"),
    /// ]
    /// ```
    ///
    /// When sorted, the expected result would be:
    ///
    /// ```
    /// [
    ///     ModelVersion(name: "Model"),
    ///     ModelVersion(name: "Model 1"),
    ///     ModelVersion(name: "Model 2"),
    ///     ModelVersion(name: "Model 10"),
    ///     ModelVersion(name: "Model 23"),
    /// ]
    /// ```
    ///
    func sortedByConvention() -> [Element] {
        sorted { left, right -> Bool in
            left.name.compare(right.name, options: [.numeric], range: nil, locale: nil) == .orderedAscending
        }
    }
}

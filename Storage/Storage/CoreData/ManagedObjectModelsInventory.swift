
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
        /// Failed to load the current `NSManagedObjectModel` version.
        case failedToLoadCurrentModel
    }

    /// Represents a single `.xcdatamodel` file (or `.mom` if compiled).
    ///
    /// This is intentionally a `struct` with a single property instead of a `String` because I
    /// foresee that this will be used to contain the `NSManagedObjectModel` in the near future.
    ///
    struct ModelVersion: Equatable {
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
    let versions: [ModelVersion]

    /// The `NSManagedObjectModel` of the current version.
    ///
    /// This should probably be in `ModelVersion.model` but I'm opting to not change the current
    /// logic that was taken from `CoreDataManager`.
    ///
    let currentModel: NSManagedObjectModel

    /// Create an instance of `self`. The `modelVersions` will be sorted using the migration
    /// sequence convention.
    ///
    init(packageURL: URL, currentModel: NSManagedObjectModel, versions: [ModelVersion]) {
        self.packageURL = packageURL
        self.currentModel = currentModel
        self.versions = versions.sortedByConvention()
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

        let currentModel = try self.currentModel(from: packageURL)

        let versionInfoFileURL = self.versionInfoFileURL(from: packageURL)
        let modelVersions = try self.modelVersions(from: versionInfoFileURL)

        return ManagedObjectModelsInventory(packageURL: packageURL,
                                            currentModel: currentModel,
                                            versions: modelVersions)
    }

    /// Load the corresponding `NSManagedObjectModel` for the given `version`.
    ///
    /// This is intentionally not part of `ModelVersion` itself because this involves a file
    /// access and we usually would not need all of the `NSManagedObjectModel` instances.
    ///
    func model(for version: ModelVersion) -> NSManagedObjectModel? {
        let expectedMomURL = packageURL.appendingPathComponent(version.name).appendingPathExtension("mom")
        return NSManagedObjectModel(contentsOf: expectedMomURL)
    }

    /// Loads the corresponding `NSManagedObjectModel` for the given `versions`.
    ///
    /// - Throws: If one of the `NSManagedObjectModels` is not found or cannot be loaded.
    func models(for versions: [ModelVersion]) throws -> [NSManagedObjectModel] {
        try versions.map { version in
            guard let model = self.model(for: version) else {
                let description = "No model found for \(version.name)"
                throw NSError(domain: "ManagedObjectModelsInventory",
                              code: 110,
                              userInfo: [NSLocalizedDescriptionKey: description])
            }

            return model
        }
    }
}

// MARK: - Utils

private extension ManagedObjectModelsInventory {

    /// Get the expected URL of the `VersionInfo.plist` file.
    ///
    static func versionInfoFileURL(from packageURL: URL) -> URL {
        packageURL.appendingPathComponent(Constants.versionInfoPlist)
    }

    /// Load the current `NSManagedObjectModel` version from the `VersionInfo.plist` inside
    /// the `packageURL` bundle.
    ///
    static func currentModel(from packageURL: URL) throws -> NSManagedObjectModel {
        // Using the `packageURL` for `NSManagedObjectModel(contentsOf:)` will inform it to
        // automatically load the current model version using the
        // `NSManagedObjectModel_CurrentVersionName` key defined in the plist.
        if let currentModel = NSManagedObjectModel(contentsOf: packageURL) {
            return currentModel
        } else {
            throw IntrospectionError.failedToLoadCurrentModel
        }
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

import Foundation
import Storage

/// Storage.SystemPlugin: ReadOnlyConvertible conformance
///
extension Storage.SystemPlugin: ReadOnlyConvertible {

    /// Updates the Storage.SystemPlugin with a readonly SystemPlugin
    ///
    public func update(with entity: Yosemite.SystemPlugin) {
        siteID = entity.siteID
        plugin = entity.plugin
        name = entity.name
        url = entity.url
        authorName = entity.authorName
        authorUrl = entity.authorUrl
        version = entity.version
        versionLatest = entity.versionLatest
        networkActivated = entity.networkActivated
        active = entity.active
    }

    /// Returns a readonly version of the Storage.SystemPlugin
    ///
    public func toReadOnly() -> SystemPlugin {
        .init(siteID: siteID,
              plugin: plugin,
              name: name,
              version: version,
              versionLatest: versionLatest,
              url: url,
              authorName: authorName,
              authorUrl: authorUrl,
              networkActivated: networkActivated,
              active: active)
    }
}

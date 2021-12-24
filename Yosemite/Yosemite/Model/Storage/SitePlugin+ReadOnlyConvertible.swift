import Foundation
import Storage

// Storage.SitePlugin: ReadOnlyConvertible conformance
//
extension Storage.SitePlugin: ReadOnlyConvertible {

    /// Updates the Storage.SitePlugin with a readonly SitePlugin
    ///
    public func update(with entity: Yosemite.SitePlugin) {
        siteID = entity.siteID
        plugin = entity.plugin
        status = entity.status.rawValue
        name = entity.name
        pluginUri = entity.pluginUri
        author = entity.author
        authorUri = entity.authorUri
        descriptionRaw = entity.descriptionRaw
        descriptionRendered = entity.descriptionRendered
        version = entity.version
        networkOnly = entity.networkOnly
        requiresPHPVersion = entity.requiresPHPVersion
        requiresWPVersion = entity.requiresWPVersion
        textDomain = entity.textDomain
    }

    /// Returns a readonly version of the Storage.SitePlugin
    ///
    public func toReadOnly() -> SitePlugin {
        .init(siteID: siteID,
              plugin: plugin,
              status: .init(rawValue: status),
              name: name,
              pluginUri: pluginUri,
              author: author,
              authorUri: authorUri,
              descriptionRaw: descriptionRaw,
              descriptionRendered: descriptionRendered,
              version: version,
              networkOnly: networkOnly,
              requiresWPVersion: requiresWPVersion,
              requiresPHPVersion: requiresPHPVersion,
              textDomain: textDomain)
    }
}

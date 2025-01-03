import Foundation
@testable import WordPressAuthenticator

struct MockPluginDirectoryProvider {
    static func getJetpackDescriptionHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let description = sections["description"] as? String else {
            return nil
        }

        return description
    }

    static func getJetpackFAQHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let faq = sections["faq"] as? String else {
            return nil
        }

        return faq
    }

    static func getJetpackInstallationHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let installation = sections["installation"] as? String else {
            return nil
        }

        return installation
    }

    static func getJetpackChangeLogHTML() -> String? {
        let loader = JSONLoader()
        let pluginDirectoryJson = loader.loadFile("plugin-directory-jetpack", type: "json")!

        guard let sections = pluginDirectoryJson["sections"],
            let changeLog = sections["changelog"] as? String else {
            return nil
        }

        return changeLog
    }

    static func getPluginDirectoryMockData(with mockName: String, sender: AnyClass, type: String = "json") throws -> Data {
        let mockPath = Bundle(for: sender).path(forResource: mockName, ofType: type)!
        let data = try Data(contentsOf: URL(fileURLWithPath: mockPath))

        return data
    }

}

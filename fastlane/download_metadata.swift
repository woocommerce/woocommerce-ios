#!/usr/bin/env swift

import Foundation

let glotPressSubtitleKey = "app_store_subtitle"
let glotPressWhatsNewKey = "v6.0-whats-new"
let glotPressDescriptionKey = "app_store_desc"
let glotPressKeywordsKey = "app_store_keywords"
let glotPressPromoTextKey = "app_store_promo_text"
let scriptDir = URL(fileURLWithPath: (CommandLine.arguments.first ?? "./main.swift")).deletingLastPathComponent()
let baseFolder = scriptDir.appendingPathComponent("metadata").path

// iTunes Connect language code: GlotPress code
let languages = [
    "ar-SA": "ar",
    "de-DE": "de",
    "default": "en-us", // Technically not a real GlotPress language
    "en-US": "en-us", // Technically not a real GlotPress language
    "es-ES": "es",
    "fr-FR": "fr",
    "he": "he",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "nl-NL": "nl",
    "pt-BR": "pt-br",
    "ru": "ru",
    "sv": "sv",
    "tr": "tr",
    "zh-Hans": "zh-cn",
    "zh-Hant": "zh-tw",
]

func downloadTranslation(languageCode: String, folderName: String) {
    let languageCodeOverride = languageCode == "en-us" ? "es" : languageCode
    let glotPressURL = "https://translate.wordpress.com/projects/woocommerce/woocommerce-ios/release-notes/\(languageCodeOverride)/default/export-translations?format=json"
    let requestURL: URL = URL(string: glotPressURL)!
    let urlRequest: URLRequest = URLRequest(url: requestURL)
    let session = URLSession.shared

    let sema = DispatchSemaphore( value: 0)

    print("Downloading Language: \(languageCode)")
	
    let task = session.dataTask(with: urlRequest) {
        (data, response, error) -> Void in

        defer {
            sema.signal()
        }

        guard let data = data else {
            print("  Invalid data downloaded.")
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data, options: []),
            let jsonDict = json as? [String: Any] else {
                print("  JSON was not returned")
                return
        }

        var subtitle: String?
        var whatsNew: String?
        var keywords: String?
        var storeDescription: String?
        var promoText: String?

        jsonDict.forEach({ (key: String, value: Any) in

            guard let index = key.firstIndex(of: Character(UnicodeScalar(0004))) else {
            	return
            }

            let keyFirstPart = String(key[..<index])

            guard let value = value as? [String],
                let firstValue = value.first else {
                    print("  No translation for \(keyFirstPart)")
                    return
            }

            var originalLanguage = String(key[index...])
            originalLanguage.remove(at: originalLanguage.startIndex)
            let translation = languageCode == "en-us" ? originalLanguage : firstValue
            
            switch keyFirstPart {
            case glotPressSubtitleKey:
                subtitle = translation
            case glotPressKeywordsKey:
                keywords = translation
            case glotPressWhatsNewKey:
                whatsNew = translation
            case glotPressDescriptionKey:
                storeDescription = translation
            case glotPressPromoTextKey:
                promoText = translation
            default:
                print("  Unknown key: \(keyFirstPart)")
            }
        })

        let languageFolder = "\(baseFolder)/\(folderName)"

        let fileManager = FileManager.default
        try? fileManager.createDirectory(atPath: languageFolder, withIntermediateDirectories: true, attributes: nil)


        do {
            let releaseNotesPath = "\(languageFolder)/release_notes.txt"

            /// Remove existing release notes in case they weren't translated for this release (that way `deliver` will fall back to the `default` locale)
            if FileManager.default.fileExists(atPath: releaseNotesPath) {
                try FileManager.default.removeItem(at: URL(fileURLWithPath: releaseNotesPath))
            }

            try subtitle?.write(toFile: "\(languageFolder)/subtitle.txt", atomically: true, encoding: .utf8)
            try whatsNew?.write(toFile: releaseNotesPath, atomically: true, encoding: .utf8)
            try keywords?.write(toFile: "\(languageFolder)/keywords.txt", atomically: true, encoding: .utf8)
            try storeDescription?.write(toFile: "\(languageFolder)/description.txt", atomically: true, encoding: .utf8)
            try promoText?.write(toFile: "\(languageFolder)/promotional_text.txt", atomically: true, encoding: .utf8)
        } catch {
            print("  Error writing: \(error)")
        }
    }
    
    task.resume()
    sema.wait()
}

languages.forEach( { (key: String, value: String) in
    downloadTranslation(languageCode: value, folderName: key)
})


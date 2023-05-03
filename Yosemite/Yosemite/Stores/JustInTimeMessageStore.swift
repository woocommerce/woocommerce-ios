import Foundation
import Experiments
import Storage
import Networking
import WooFoundation

// MARK: - JustInTimeMessageStore
//
public class JustInTimeMessageStore: Store {
    private let remote: JustInTimeMessagesRemoteProtocol
    private let imageService: ImageService
    private let featureFlagService: FeatureFlagService

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                imageService: ImageService,
                featureFlagService: FeatureFlagService = DefaultFeatureFlagService()) {
        self.remote = JustInTimeMessagesRemote(network: network)
        self.imageService = imageService
        self.featureFlagService = featureFlagService
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: JustInTimeMessageAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? JustInTimeMessageAction else {
            assertionFailure("JustInTimeMessageStore received an unsupported action")
            return
        }


        switch action {
        case .loadMessage(let siteID, let screen, let hook, let completion):
            loadMessage(for: siteID, screen: screen, hook: hook, completion: completion)
        case .dismissMessage(let message, let siteID, let completion):
            dismissMessage(message, for: siteID, completion: completion)
        }
    }
}

// MARK: - Services
//
private extension JustInTimeMessageStore {
    /// Retrieves the top `JustInTimeMessage` from the API for a given screen and hook
    ///
    func loadMessage(for siteID: Int64,
                     screen: String,
                     hook: JustInTimeMessageHook,
                     completion: @escaping (Result<[JustInTimeMessage], Error>) -> ()) {
        Task {
            let result = await Result {
                let messages = try await remote.loadAllJustInTimeMessages(
                    for: siteID,
                    messagePath: .init(app: .wooMobile,
                                       screen: screen,
                                       hook: hook),
                    query: justInTimeMessageQuery(),
                    locale: localeLanguageRegionIdentifier())

                return await displayMessages(messages)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }

    func justInTimeMessageQuery() -> [String: String] {
        var queryItems = [
            "platform": "ios",
            "version": Bundle.main.marketingVersion
        ]

        if let device = deviceIdiomName() {
            queryItems["device"] = device
        }

        if let buildType = buildType() {
            queryItems["build_type"] = buildType
        }

        return queryItems
    }

    func deviceIdiomName() -> String? {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return "phone"
        case .pad:
            return "pad"
        default:
            return nil
        }
    }

    func buildType() -> String? {
#if DEBUG || ALPHA
        return "developer"
#else
        return nil
#endif
    }

    func localeLanguageRegionIdentifier() -> String? {
        guard let languageCode = Locale.current.languageCode else {
            return nil
        }
        guard let regionCode = Locale.current.regionCode else {
            return languageCode
        }
        return "\(languageCode)_\(regionCode)"
    }

    func displayMessages(_ messages: [Networking.JustInTimeMessage]) async -> [JustInTimeMessage] {
        var displayMessages = [JustInTimeMessage]()
        for message in messages {
            let backgroundAsset = await self.imageAsset(ofKind: .background, from: message)
            let badgeAsset = await self.imageAsset(ofKind: .badge, from: message)
            displayMessages.append(JustInTimeMessage(message: message, background: backgroundAsset, badge: badgeAsset))
        }
        return displayMessages
    }

    /// Attempts to retrieve from cache, or download, light and dark mode images for the specified kind of image, and bundle them in an asset.
    /// Images will be cached by the ImageService.
    /// - Parameters:
    ///   - ofKind: intended image semantics, e.g. background or badge
    ///   - message: the Just in Time Message to get images for
    /// - Returns: UIImageAsset, with dark and light mode images, for the current device's screen density
    func imageAsset(ofKind assetKind: ImageAssetKind,
                    from message: Networking.JustInTimeMessage) async -> UIImageAsset? {
        guard featureFlagService.isFeatureFlagEnabled(.tapToPayOnIPhoneMilestone3),
              let url = message.assets[assetKind.baseUrlKey],
              let lightImage = await image(for: url) else {
            return nil
        }

        let asset = UIImageAsset()
        asset.register(lightImage, with: UITraitCollection(userInterfaceStyle: .unspecified))

        if let darkImageUrl = message.assets[assetKind.darkUrlKey],
           let darkImage = await image(for: darkImageUrl) {
            asset.register(darkImage, with: UITraitCollection(userInterfaceStyle: .dark))
        }

        return asset
    }

    func image(for url: URL) async -> UIImage? {
        do {
            let image = try await withCheckedThrowingContinuation { [weak self] continuation in
                self?.imageService.retrieveImageFromCache(with: url) { [weak self] image in
                    if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        _ = self?.imageService.downloadImage(with: url, shouldCacheImage: true) { image, error in
                            if let image = image {
                                continuation.resume(returning: image)
                            } else {
                                continuation.resume(throwing: error ?? .failedToDownloadImage)
                            }
                        }
                    }
                }
            }
            return image
        } catch ImageServiceError.other(error: let error) {
            DDLogError("⛔️ Error while downloading JITM image: \(error.localizedDescription)")
            return nil
        } catch {
            DDLogError("⛔️ Error while downloading JITM image: \(error.localizedDescription)")
            return nil
        }
    }

    func dismissMessage(_ message: JustInTimeMessage,
                        for siteID: Int64,
                        completion: @escaping (Result<Bool, Error>) -> ()) {
        Task {
            let result = await Result {
                try await remote.dismissJustInTimeMessage(for: siteID,
                                                                   messageID: message.messageID,
                                                                   featureClass: message.featureClass)
            }

            await MainActor.run {
                completion(result)
            }
        }
    }

    enum ImageAssetKind {
        case background
        case badge

        var baseUrlKey: String {
            return baseUrlKeyPrefix + Constants.urlKeySuffix
        }

        var darkUrlKey: String {
            return darkUrlKeyPrefix + Constants.urlKeySuffix
        }

        private var darkUrlKeyPrefix: String {
            return baseUrlKeyPrefix + Constants.darkKeySuffix
        }

        private var baseUrlKeyPrefix: String {
            switch self {
            case .background:
                return "background_image"
            case .badge:
                return "badge_image"
            }
        }

        enum Constants {
            static let urlKeySuffix = "_url"
            static let darkKeySuffix = "_dark"
        }
    }
}

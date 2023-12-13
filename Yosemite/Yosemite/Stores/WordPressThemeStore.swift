import Foundation
import Networking
import Storage

// MARK: - WordPressThemeStore
//
public final class WordPressThemeStore: Store {
    private let remote: WordPressThemeRemoteProtocol

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: WordPressThemeRemoteProtocol) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Initializes a new WordPressThemeStore.
    /// - Parameters:
    ///   - dispatcher: The dispatcher used to subscribe to `WordPressThemeAction`.
    ///   - network: The network layer used to fetch theme details
    ///
    public convenience override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: WordPressThemeRemote(network: network))
    }

    // MARK: - Actions

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WordPressThemeAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `WordPressThemeAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? WordPressThemeAction else {
            assertionFailure("WordPressThemeStore received an unsupported action")
            return
        }

        switch action {
        case .loadSuggestedThemes(let onCompletion):
            loadSuggestedThemes(onCompletion: onCompletion)
        case let .loadCurrentTheme(siteID, onCompletion):
            loadCurrentTheme(siteID: siteID, onCompletion: onCompletion)
        case let .installTheme(themeID, siteID, onCompletion):
            installTheme(themeID: themeID, siteID: siteID, onCompletion: onCompletion)
        case let .activateTheme(themeID, siteID, onCompletion):
            activateTheme(themeID: themeID, siteID: siteID, onCompletion: onCompletion)
        }
    }
}

private extension WordPressThemeStore {

    func loadSuggestedThemes(onCompletion: @escaping (Result<[WordPressTheme], Error>) -> Void) {
        Task { @MainActor in
            do {
                let themes = try await remote.loadSuggestedThemes()
                onCompletion(.success(themes))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func loadCurrentTheme(siteID: Int64, onCompletion: @escaping (Result<WordPressTheme, Error>) -> Void) {
        Task { @MainActor in
            do {
                let theme = try await remote.loadCurrentTheme(siteID: siteID)
                onCompletion(.success(theme))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func installTheme(themeID: String,
                      siteID: Int64,
                      onCompletion: @escaping (Result<WordPressTheme, Error>) -> Void) {
        Task { @MainActor in
            do {
                let theme = try await remote.installTheme(themeID: themeID, siteID: siteID)
                onCompletion(.success(theme))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }

    func activateTheme(themeID: String,
                       siteID: Int64,
                       onCompletion: @escaping (Result<WordPressTheme, Error>) -> Void) {
        Task { @MainActor in
            do {
                let theme = try await remote.activateTheme(themeID: themeID, siteID: siteID)
                onCompletion(.success(theme))
            } catch {
                onCompletion(.failure(error))
            }
        }
    }
}

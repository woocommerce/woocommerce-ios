import Foundation
import Yosemite
import class Networking.AlamofireNetwork

enum SetupStep: Int, CaseIterable {
    case connect = 0
    case checkPlugin = 1
    case enablePush = 2
}

@MainActor
protocol WPComConnectionSetupHandlerDelegate: AnyObject {
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status)
    func setupDidComplete()
}

@MainActor
protocol WPComConnectionSetupHandlerProtocol: AnyObject {
    var delegate: WPComConnectionSetupHandlerDelegate? { get set }
    func start()
    func retry()
    func cancel()
}

@MainActor
final class WPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private let siteURL: String
    private let wpcomCredentials: Credentials?
    private let pluginChecker: PluginVersionCheckerProtocol
    private let stores: StoresManager

    private var currentTask: Task<Void, Never>?
    private var lastFailedStep: SetupStep?

    init(siteURL: String,
         wpcomCredentials: Credentials?,
         pluginChecker: PluginVersionCheckerProtocol,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.wpcomCredentials = wpcomCredentials
        self.pluginChecker = pluginChecker
        self.stores = stores
    }

    func start() {
        startFromStep(.connect)
    }

    func retry() {
        let startStep = lastFailedStep ?? .connect
        lastFailedStep = nil
        startFromStep(startStep)
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}

private extension WPComConnectionSetupHandler {
    func startFromStep(_ step: SetupStep) {
        guard currentTask == nil else { return }

        currentTask = Task { [weak self] in
            guard let self else { return }
            defer { self.currentTask = nil }

            if step.rawValue <= SetupStep.connect.rawValue {
                guard await executeConnectStep() else { return }
            }

            if step.rawValue <= SetupStep.checkPlugin.rawValue {
                await executePluginCheckStep()
            }
        }
    }

    func executeConnectStep() async -> Bool {
        guard let wpcomCredentials else {
            delegate?.stepDidUpdate(.connect, status: .success)
            return true
        }

        delegate?.stepDidUpdate(.connect, status: .running)

        do {
            try await performConnection(with: wpcomCredentials)

            if Task.isCancelled { return false }

            delegate?.stepDidUpdate(.connect, status: .success)
            return true
        } catch {
            if Task.isCancelled { return false }

            DDLogError("⛔️ WPCom connection failed: \(error)")
            lastFailedStep = .connect
            delegate?.stepDidUpdate(.connect, status: .failure(reason: Localization.connectionError))
            return false
        }
    }

    func performConnection(with credentials: Credentials) async throws {
        let connectionData = try await dispatch(JetpackConnectionAction.fetchJetpackConnectionData)
        if connectionData.currentUser.wpcomUser != nil {
            DDLogDebug("📱 WPCom connection: Site already connected")
            return
        }

        let blogID: Int64
        if let existingBlogID = connectionData.blogID, connectionData.isRegistered == true {
            blogID = existingBlogID
        } else {
            blogID = try await dispatch(JetpackConnectionAction.registerSite)
        }

        let provisionResponse = try await dispatch(JetpackConnectionAction.provisionConnection)

        let network = AlamofireNetwork(credentials: credentials, selectedSite: nil, appPasswordSupportState: nil)
        let siteURL = self.siteURL
        try await dispatch { completion in
            JetpackConnectionAction.finalizeConnection(
                siteID: blogID,
                siteURL: siteURL,
                provisionResponse: provisionResponse,
                network: network,
                completion: completion
            )
        }

        let verificationData = try await dispatch(JetpackConnectionAction.fetchJetpackConnectionData)
        guard verificationData.currentUser.wpcomUser != nil else {
            throw WPComConnectionError.verificationFailed
        }

        DDLogDebug("📱 WPCom connection: Successfully connected")
    }

    func executePluginCheckStep() async {
        delegate?.stepDidUpdate(.checkPlugin, status: .running)

        do {
            let result = try await pluginChecker.checkCompatibility()

            if Task.isCancelled { return }

            switch result {
            case .compatible:
                delegate?.stepDidUpdate(.checkPlugin, status: .success)
                delegate?.setupDidComplete()

            case .incompatible(let currentVersion, _):
                lastFailedStep = .checkPlugin
                let message = String(format: Localization.pluginOutdatedFormat, currentVersion)
                delegate?.stepDidUpdate(.checkPlugin, status: .failure(reason: message))
            }
        } catch {
            if Task.isCancelled { return }

            DDLogError("⛔️ Plugin compatibility check failed: \(error)")
            lastFailedStep = .checkPlugin
            delegate?.stepDidUpdate(.checkPlugin, status: .failure(reason: Localization.connectionError))
        }
    }

    func dispatch<T>(_ actionBuilder: @escaping (@escaping (Result<T, Error>) -> Void) -> Action) async throws -> T {
        let stores = self.stores
        return try await withCheckedThrowingContinuation { continuation in
            let action = actionBuilder { result in
                continuation.resume(with: result)
            }
            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }
}

private extension WPComConnectionSetupHandler {
    enum Localization {
        static let connectionError = NSLocalizedString(
            "wpComConnectionSetupHandler.connectionError",
            value: "There was an error completing your request. Please try again or contact support.",
            comment: "Generic error message for WPCom connection setup failures"
        )

        static let pluginOutdatedFormat = NSLocalizedString(
            "wpComConnectionSetupHandler.pluginOutdated",
            value: "Your WooCommerce plugin version %@ needs updating to connect your store.",
            comment: "Error message when WooCommerce plugin is outdated. %@ is the current version."
        )
    }
}

enum WPComConnectionError: Error {
    case verificationFailed
}

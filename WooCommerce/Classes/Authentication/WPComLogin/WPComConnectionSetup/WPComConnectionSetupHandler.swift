import Foundation

/// Type-safe step identifiers for the WPCom connection setup flow
enum SetupStep: Int, CaseIterable {
    case connect = 0
    case checkPlugin = 1
    case enablePush = 2
}

/// Delegate for receiving setup progress updates.
/// Marked @MainActor to ensure all callbacks are on main thread.
@MainActor
protocol WPComConnectionSetupHandlerDelegate: AnyObject {
    /// Called when a step's status changes (notStarted → running → success/failure)
    func stepDidUpdate(_ step: SetupStep, status: WPComConnectionSetupStep.Status)

    /// Called when the entire setup process completes successfully
    func setupDidComplete()
}

/// Protocol for the connection setup handler
protocol WPComConnectionSetupHandlerProtocol: AnyObject {
    var delegate: WPComConnectionSetupHandlerDelegate? { get set }
    func start()
    func retry()
    func cancel()
}

/// Handles the WPCom connection setup flow.
/// Orchestrates the connection and plugin compatibility check steps.
final class WPComConnectionSetupHandler: WPComConnectionSetupHandlerProtocol {
    weak var delegate: WPComConnectionSetupHandlerDelegate?

    private let connectionService: WPComConnectionServiceProtocol
    private let pluginChecker: PluginCompatibilityCheckerProtocol

    private var currentTask: Task<Void, Never>?
    private var lastFailedStep: SetupStep?

    init(connectionService: WPComConnectionServiceProtocol,
         pluginChecker: PluginCompatibilityCheckerProtocol) {
        self.connectionService = connectionService
        self.pluginChecker = pluginChecker
    }

    func start() {
        startFromStep(.connect)
    }

    func retry() {
        // Retry from the failed step, or from beginning if none failed
        let startStep = lastFailedStep ?? .connect
        lastFailedStep = nil
        startFromStep(startStep)
    }

    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }

    private func startFromStep(_ step: SetupStep) {
        // Guard against double-start
        guard currentTask == nil else { return }

        currentTask = Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.currentTask = nil }

            // Step 1: Connect to WordPress.com (skip if retrying from later step)
            if step.rawValue <= SetupStep.connect.rawValue {
                self.delegate?.stepDidUpdate(.connect, status: .running)

                do {
                    try await self.connectionService.connect()

                    // Check for cancellation
                    if Task.isCancelled { return }

                    self.delegate?.stepDidUpdate(.connect, status: .success)
                } catch {
                    if Task.isCancelled { return }

                    DDLogError("⛔️ WPCom connection failed: \(error)")
                    self.lastFailedStep = .connect
                    self.delegate?.stepDidUpdate(.connect, status: .failure(reason: Localization.connectionError))
                    return
                }
            }

            // Step 2: Check plugin compatibility
            if step.rawValue <= SetupStep.checkPlugin.rawValue {
                self.delegate?.stepDidUpdate(.checkPlugin, status: .running)

                do {
                    let result = try await self.pluginChecker.checkCompatibility()

                    // Check for cancellation
                    if Task.isCancelled { return }

                    switch result {
                    case .compatible:
                        self.delegate?.stepDidUpdate(.checkPlugin, status: .success)
                        self.delegate?.setupDidComplete()

                    case .incompatible(let currentVersion, _):
                        self.lastFailedStep = .checkPlugin
                        let message = String(format: Localization.pluginOutdatedFormat, currentVersion)
                        self.delegate?.stepDidUpdate(.checkPlugin, status: .failure(reason: message))
                    }
                } catch {
                    if Task.isCancelled { return }

                    DDLogError("⛔️ Plugin compatibility check failed: \(error)")
                    self.lastFailedStep = .checkPlugin
                    self.delegate?.stepDidUpdate(.checkPlugin, status: .failure(reason: Localization.connectionError))
                }
            }

            // Step 3: Enable push notifications (WOOMOB-1932 - future)
            // Will be added here when implementing that ticket
        }
    }
}

// MARK: - Localization
private extension WPComConnectionSetupHandler {
    enum Localization {
        static let connectionError = NSLocalizedString(
            "wpComConnectionSetupHandler.connectionError",
            value: "There was an error completing your request. Please try again or contact support if this error continues.",
            comment: "Generic error message for WPCom connection setup failures"
        )

        static let pluginOutdatedFormat = NSLocalizedString(
            "wpComConnectionSetupHandler.pluginOutdated",
            value: "Your current WooCommerce plugin version %@ needs updating to fully connect your store to WordPress.com.",
            comment: "Error message when WooCommerce plugin version is too old. %@ is the current version."
        )
    }
}

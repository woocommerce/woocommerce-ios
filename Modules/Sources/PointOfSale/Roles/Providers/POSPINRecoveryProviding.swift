import SwiftUI
import UIKit

public enum POSPINRecoveryResult: Equatable, Sendable {
    case verified(siteID: Int64)
    case canceled
    case failed
}

@MainActor
public protocol POSPINRecoveryProviding {
    func authenticateForPINRecovery(siteID: Int64, from presenter: UIViewController) async -> POSPINRecoveryResult
}

typealias POSPINRecoveryAuthentication = @MainActor (Int64) async -> POSPINRecoveryResult

@MainActor
final class POSLockPresenter {
    weak var controller: UIViewController?
    private var recoveryTask: Task<Void, Never>?

    func startRecovery(_ recover: @escaping @MainActor (UIViewController) async -> Void) -> Bool {
        guard recoveryTask == nil, let controller else { return false }
        recoveryTask = Task { [weak self] in
            await recover(controller)
            if self?.controller === controller {
                self?.recoveryTask = nil
            }
        }
        return true
    }

    func removeController() {
        controller = nil
        cancelRecovery()
        recoveryTask = nil
    }

    func cancelRecovery() {
        recoveryTask?.cancel()
    }
}

private struct POSLockPresenterKey: EnvironmentKey {
    static let defaultValue: POSLockPresenter? = nil
}

private struct POSPINRecoveryKey: EnvironmentKey {
    static let defaultValue: POSPINRecoveryProviding? = nil
}

extension EnvironmentValues {
    var posLockPresenter: POSLockPresenter? {
        get { self[POSLockPresenterKey.self] }
        set { self[POSLockPresenterKey.self] = newValue }
    }

    var posPINRecovery: POSPINRecoveryProviding? {
        get { self[POSPINRecoveryKey.self] }
        set { self[POSPINRecoveryKey.self] = newValue }
    }
}

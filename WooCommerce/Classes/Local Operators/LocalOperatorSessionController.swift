import Combine
import Foundation
import UIKit

@MainActor
protocol LocalOperatorSessionControlling: AnyObject, LocalOperatorCapabilitiesProviding {
    var profiles: [LocalOperatorProfile] { get }
    var inactivityTimeout: TimeInterval { get set }
    var isLocked: Bool { get }
    var requiresBootstrap: Bool { get }
    func reload()
    func enableDeviceStaffMode()
    func disableDeviceStaffMode()
    func bootstrapManager(displayName: String, pin: String) throws
    @discardableResult func unlock(operatorID: UUID, pin: String) -> Bool
    func lock()
    func registerActivity()
    func addOperator(displayName: String, role: LocalOperatorRole, pin: String) throws
    func updateOperator(_ profile: LocalOperatorProfile, newPIN: String?) throws
    func deleteOperator(_ profile: LocalOperatorProfile)
}

@MainActor
final class LocalOperatorSessionController: ObservableObject, LocalOperatorSessionControlling {
    @Published private(set) var profiles: [LocalOperatorProfile]
    @Published private(set) var activeOperator: LocalOperatorProfile?
    @Published private(set) var isLocked: Bool
    @Published private(set) var requiresBootstrap: Bool

    private let store: LocalOperatorStoreProtocol
    private let pinVerificationService: PINVerificationServiceProtocol
    private let notificationCenter: NotificationCenter
    private var notificationObservers: [NSObjectProtocol] = []
    private var inactivityTimer: Timer?
    private var lastActivityAt: Date?

    init(store: LocalOperatorStoreProtocol = LocalOperatorStore(),
         pinVerificationService: PINVerificationServiceProtocol = PINVerificationService(),
         notificationCenter: NotificationCenter = .default) {
        let profiles = store.loadProfiles().sorted(by: Self.sortProfiles)
        let isEnabled = store.settings.isDeviceStaffModeEnabled
        self.store = store
        self.pinVerificationService = pinVerificationService
        self.notificationCenter = notificationCenter
        self.profiles = profiles
        self.requiresBootstrap = isEnabled && profiles.isEmpty
        self.isLocked = isEnabled

        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppWillResignActive()
            }
        })

        notificationObservers.append(notificationCenter.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleAppDidBecomeActive()
            }
        })
    }

    deinit {
        notificationObservers.forEach(notificationCenter.removeObserver)
    }

    var isDeviceStaffModeEnabled: Bool {
        store.settings.isDeviceStaffModeEnabled
    }

    var inactivityTimeout: TimeInterval {
        get { store.settings.inactivityTimeout }
        set {
            var settings = store.settings
            settings.inactivityTimeout = newValue
            store.settings = settings
            resetInactivityTimer()
        }
    }

    var currentCapabilities: LocalOperatorCapabilities {
        guard isDeviceStaffModeEnabled else {
            return .unrestricted
        }
        return activeOperator?.role.capabilities ?? .cashier
    }

    func canViewAnalytics() -> Bool {
        currentCapabilities.canViewAnalytics
    }

    func canAccessAdminSettings() -> Bool {
        currentCapabilities.canAccessAdminSettings
    }

    func canManageLocalOperators() -> Bool {
        currentCapabilities.canManageLocalOperators
    }

    func reload() {
        profiles = store.loadProfiles().sorted(by: Self.sortProfiles)
        requiresBootstrap = isDeviceStaffModeEnabled && profiles.isEmpty
        if let activeOperator, profiles.contains(where: { $0.id == activeOperator.id && $0.isEnabled }) == false {
            lock()
        }
    }

    func enableDeviceStaffMode() {
        var settings = store.settings
        settings.isDeviceStaffModeEnabled = true
        store.settings = settings
        reload()
        if profiles.isEmpty {
            requiresBootstrap = true
        } else {
            lock()
        }
    }

    func disableDeviceStaffMode() {
        var settings = store.settings
        settings.isDeviceStaffModeEnabled = false
        store.settings = settings
        activeOperator = nil
        isLocked = false
        requiresBootstrap = false
        invalidateTimer()
    }

    func bootstrapManager(displayName: String, pin: String) throws {
        let profile = LocalOperatorProfile(displayName: displayName, role: .manager)
        try pinVerificationService.storePIN(pin, for: profile.pinReference)
        profiles = [profile]
        store.saveProfiles(profiles)
        requiresBootstrap = false
        _ = unlock(operatorID: profile.id, pin: pin)
    }

    @discardableResult
    func unlock(operatorID: UUID, pin: String) -> Bool {
        guard isDeviceStaffModeEnabled,
              let profile = profiles.first(where: { $0.id == operatorID && $0.isEnabled }),
              pinVerificationService.verifyPIN(pin, for: profile.pinReference) else {
            return false
        }

        activeOperator = profile
        isLocked = false
        requiresBootstrap = false
        registerActivity()
        return true
    }

    func lock() {
        guard isDeviceStaffModeEnabled else {
            return
        }
        activeOperator = nil
        isLocked = true
        invalidateTimer()
    }

    func registerActivity() {
        lastActivityAt = Date()
        resetInactivityTimer()
    }

    func addOperator(displayName: String, role: LocalOperatorRole, pin: String) throws {
        let profile = LocalOperatorProfile(displayName: displayName, role: role)
        try pinVerificationService.storePIN(pin, for: profile.pinReference)
        profiles.append(profile)
        persistProfiles()
    }

    func updateOperator(_ profile: LocalOperatorProfile, newPIN: String?) throws {
        guard let index = profiles.firstIndex(where: { $0.id == profile.id }) else {
            return
        }
        profiles[index] = profile
        if let newPIN, newPIN.isNotEmpty {
            try pinVerificationService.storePIN(newPIN, for: profile.pinReference)
        }
        if activeOperator?.id == profile.id {
            activeOperator = profile
        }
        persistProfiles()
    }

    func deleteOperator(_ profile: LocalOperatorProfile) {
        profiles.removeAll { $0.id == profile.id }
        pinVerificationService.deletePIN(for: profile.pinReference)
        if activeOperator?.id == profile.id {
            lock()
        }
        persistProfiles()
        requiresBootstrap = isDeviceStaffModeEnabled && profiles.isEmpty
    }
}

private extension LocalOperatorSessionController {
    static func sortProfiles(lhs: LocalOperatorProfile, rhs: LocalOperatorProfile) -> Bool {
        if lhs.role != rhs.role {
            return lhs.role == .manager
        }
        return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
    }

    func persistProfiles() {
        profiles.sort(by: Self.sortProfiles)
        store.saveProfiles(profiles)
    }

    func invalidateTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }

    func resetInactivityTimer() {
        invalidateTimer()
        guard isDeviceStaffModeEnabled, isLocked == false else {
            return
        }
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: inactivityTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.lock()
            }
        }
    }

    func handleAppWillResignActive() {
        invalidateTimer()
    }

    func handleAppDidBecomeActive() {
        guard isDeviceStaffModeEnabled else {
            return
        }
        if let lastActivityAt, Date().timeIntervalSince(lastActivityAt) >= inactivityTimeout {
            lock()
        } else if isLocked == false {
            resetInactivityTimer()
        }
    }
}

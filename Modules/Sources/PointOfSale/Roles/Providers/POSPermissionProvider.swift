import Foundation
import Observation
import struct Networking.POSStaffMember
import enum Networking.POSAuthError

/// POS permission provider for the M1 server-side design.
///
/// Source of truth for the staff list is `GET /wc-pos/v1/staff`, fetched on
/// POS entry and again whenever an entered PIN doesn't match the cached
/// hashes. Validation is local — the cached `POSStaffMember.pinHash` (PBKDF2-SHA256
/// of `pinSalt + pin`) is compared on-device, so a PIN never leaves the device.
///
/// Capability gating is hardcoded per role (admin/shop_manager full,
/// `pos_manager` reduced, `pos_cashier` minimal) per the M1 capability matrix.
@Observable
public final class POSPermissionProvider: POSPermissionProviding {

    // MARK: - Public state

    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool

    /// Whether at least one cached staff member has a PIN configured.
    /// When `false`, the lock screen is bypassed and the device admin operates POS
    /// with full capabilities — covers the first-launch case before the admin has
    /// set any PINs on the web.
    public var hasAnyPINs: Bool {
        staff.contains(where: \.hasPIN)
    }

    public var autoLockTimeoutSeconds: Int { Int(Self.autoLockTimeout) }

    // MARK: - Auto-lock

    public static let autoLockTimeout: TimeInterval = 300

    // MARK: - Cached staff list (in-memory mirror of `staffCache`)

    public private(set) var staff: [POSStaffMember]

    // MARK: - Dependencies

    private let staffCache: POSStaffCaching
    private let verifier: POSPBKDF2Verifier
    private let rateLimiter: POSLocalRateLimiter
    private let fetchStaffRemote: () async throws -> [POSStaffMember]
    private let appAccountUserID: Int64
    private let appAccountDisplayName: String

    // MARK: - Private state

    private static let isLockedKey = POSLockStateKey.isLocked
    private var autoLockTimer: Timer?

    // MARK: - Init

    public init(appAccountUserID: Int64,
                appAccountDisplayName: String,
                fetchStaffRemote: @escaping () async throws -> [POSStaffMember],
                staffCache: POSStaffCaching = POSStaffCache(),
                verifier: POSPBKDF2Verifier = POSPBKDF2Verifier(),
                rateLimiter: POSLocalRateLimiter = POSLocalRateLimiter()) {
        self.appAccountUserID = appAccountUserID
        self.appAccountDisplayName = appAccountDisplayName
        self.fetchStaffRemote = fetchStaffRemote
        self.staffCache = staffCache
        self.verifier = verifier
        self.rateLimiter = rateLimiter
        self.staff = staffCache.load()
        self.isLocked = UserDefaults.standard.bool(forKey: Self.isLockedKey)
    }

    // MARK: - POSPermissionProviding

    public func hasCapability(_ capability: String) -> Bool {
        currentOperator?.hasCapability(capability) ?? false
    }

    /// Two-tier permission check. When no PINs are configured, every action is allowed
    /// (no security boundary). Otherwise returns `.allowed` if the current operator has
    /// the capability, else `.requiresOverride` so the caller can present the modal.
    public func checkPermission(_ capability: String) -> POSPermissionResult {
        guard hasAnyPINs else { return .allowed }
        resetInactivityTimer()
        return hasCapability(capability) ? .allowed : .requiresOverride
    }

    /// Verifies the entered manager PIN against the cached staff hashes and confirms
    /// the matched staff member holds `capability`. Does **not** sign the manager in —
    /// the current operator stays the cashier; the caller attaches the approver's
    /// user id as `_pos_override_user_id` meta to the next request.
    ///
    /// Refetches `/staff` once on cache miss before failing, mirroring `authenticatePIN`.
    public func requestManagerApproval(managerPIN: String,
                                       for capability: String) async throws -> POSOperator {
        try rateLimiter.checkAllowed()

        if let approver = matchOverrideOperator(forPIN: managerPIN, capability: capability) {
            rateLimiter.reset()
            return approver
        }

        await refreshPINStatus()
        if let approver = matchOverrideOperator(forPIN: managerPIN, capability: capability) {
            rateLimiter.reset()
            return approver
        }

        rateLimiter.recordFailure()
        throw (try? rateLimiter.errorForCurrentState(fallback: .invalidPIN)) ?? POSAuthError.invalidPIN
    }

    private func matchOverrideOperator(forPIN pin: String, capability: String) -> POSOperator? {
        for member in staff where member.hasPIN {
            guard verifier.verify(pin: pin, member: member) else { continue }
            let approver = makeOperator(for: member)
            // The approver must themselves hold the capability they're authorizing,
            // otherwise this is just a same-role re-entry and shouldn't count.
            guard approver.hasCapability(capability) else { continue }
            return approver
        }
        return nil
    }

    public func signIn(_ posOperator: POSOperator) {
        currentOperator = posOperator
        isLocked = false
        UserDefaults.standard.set(false, forKey: Self.isLockedKey)
        startAutoLockTimer()
    }

    public func lock() {
        autoLockTimer?.invalidate()
        autoLockTimer = nil
        currentOperator = nil
        isLocked = true
        UserDefaults.standard.set(true, forKey: Self.isLockedKey)
    }

    public func resetInactivityTimer() {
        guard currentOperator != nil else { return }
        startAutoLockTimer()
    }

    /// Fetches the staff list from `GET /wc-pos/v1/staff` and securely caches it.
    ///
    /// Called on POS entry (via `POSLockScreenModel.init`) and after an unrecognized
    /// PIN to ensure the local cache reflects any web-admin changes.
    ///
    /// If the fetched list has no PINs configured and POS was locked, also clears
    /// the lock flag so a previously-locked session doesn't trap the operator at a
    /// lock screen no one can unlock — the case when admin deletes all PINs while
    /// POS is locked.
    ///
    /// On fetch failure the cached value is left untouched so the lock screen
    /// stays up and preserves the security boundary.
    public func refreshPINStatus() async {
        do {
            let fetched = try await fetchStaffRemote()
            staff = fetched
            try? staffCache.save(fetched)
            if !hasAnyPINs && isLocked {
                isLocked = false
                UserDefaults.standard.set(false, forKey: Self.isLockedKey)
            }
        } catch {
            // Leave cached staff in place; default `hasAnyPINs` semantics keep the lock screen up.
        }
    }

    // MARK: - Local PIN authentication

    /// Whether too many failed PIN attempts have permanently locked the device.
    /// The only recovery is to log out.
    public var isPermanentlyLocked: Bool {
        rateLimiter.isPermanentlyLocked
    }

    /// Validates `pin` against the cached staff hashes. On a cache miss, refetches
    /// the staff list once and retries before reporting an invalid PIN — covers the
    /// case where the admin just set a new PIN on the web and the cache is stale.
    ///
    /// Throws `POSAuthError.rateLimited` if the rate limiter cuts in, or
    /// `POSAuthError.invalidPIN` if no staff member matches after the refetch.
    @discardableResult
    public func authenticatePIN(_ pin: String) async throws -> POSOperator {
        try rateLimiter.checkAllowed()

        if let matched = matchOperator(forPIN: pin) {
            rateLimiter.reset()
            signIn(matched)
            return matched
        }

        // Cache miss: re-fetch in case the admin updated PINs on the web since last sync.
        await refreshPINStatus()
        if let matched = matchOperator(forPIN: pin) {
            rateLimiter.reset()
            signIn(matched)
            return matched
        }

        rateLimiter.recordFailure()
        throw (try? rateLimiter.errorForCurrentState(fallback: .invalidPIN)) ?? POSAuthError.invalidPIN
    }

    private func matchOperator(forPIN pin: String) -> POSOperator? {
        for member in staff where member.hasPIN {
            if verifier.verify(pin: pin, member: member) {
                return makeOperator(for: member)
            }
        }
        return nil
    }

    private func makeOperator(for member: POSStaffMember) -> POSOperator {
        POSOperator(
            userID: member.userID,
            displayName: member.displayName,
            role: member.role,
            capabilities: Self.capabilities(forRole: member.role),
            isAppAccountHolder: member.userID == appAccountUserID
        )
    }

    // MARK: - Capability matrix (M1)

    /// Hardcoded role → capability mapping per the M1 plan capability matrix.
    ///
    /// In M1 there is no manager-override affordance: cells marked "Override (M3; no in M1)"
    /// are excluded here, so the corresponding UI is gated out for lower roles.
    static func capabilities(forRole role: String) -> Set<String> {
        switch role {
        case "administrator", "shop_manager":
            // Device admin / shop manager get full access to every POS-gated capability.
            return Set(POSCapability.allCases.map(\.rawValue))
        case "pos_manager":
            return [
                POSCapability.viewPOSSettings.rawValue,
                POSCapability.refundShopOrders.rawValue,
                POSCapability.publishCoupons.rawValue
                // editPOSSettings deliberately omitted — admin only per the matrix.
            ]
        case "pos_cashier":
            // M1: cashier has no capability-gated affordances. Process sales / view orders /
            // apply existing coupons aren't gated by `POSCapability` because the iOS app
            // doesn't check those at any call site.
            return []
        default:
            return []
        }
    }

    // MARK: - Auto-lock timer

    private func startAutoLockTimer() {
        autoLockTimer?.invalidate()
        let timer = Timer(timeInterval: TimeInterval(autoLockTimeoutSeconds), repeats: false) { [weak self] _ in
            self?.lock()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoLockTimer = timer
    }
}

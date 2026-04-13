# POS Roles & Permissions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add role-based access control to WooCommerce POS on iOS with two interchangeable providers (local/remote), PIN-based lock screen, and manager override workflow.

**Architecture:** Shared `POSPermissionProviding` protocol with `LocalPOSPermissionProvider` (on-device PINs, hardcoded capabilities) and `RemotePOSPermissionProvider` (REST API PIN auth, Application Passwords, server capabilities). Feature flags control which is active. All UI code is shared.

**Tech Stack:** Swift, SwiftUI, Observation framework, Swift Testing, iOS Keychain, WooCommerce REST API v3

**Spec:** `docs/superpowers/specs/2026-04-09-pos-roles-permissions-design.md`

**Branch:** `feature/pos-roles-permissions`

---

## File Structure

```
Modules/Sources/PointOfSale/
  Roles/
    Models/
      POSOperator.swift                    # Current POS operator identity + capabilities
      POSPermissionResult.swift            # .allowed / .requiresOverride enum
    Providers/
      POSPermissionProviding.swift         # Protocol both providers conform to
      LocalPOSPermissionProvider.swift     # On-device PINs, hardcoded caps
      RemotePOSPermissionProvider.swift    # REST API PIN auth, App Passwords
    Services/
      POSPINService.swift                  # Local PIN hash/verify (Keychain)
      POSApprovalService.swift             # Manager approval token flow (remote)
    Views/
      POSPINEntryView.swift                # Reusable PIN numpad component
      POSLockScreenView.swift              # Lock screen wrapping PIN entry + staff list
      POSManagerOverrideView.swift         # Override modal for restricted actions
      POSStaffSettingsView.swift           # Staff PIN management in Settings
    Environment/
      POSPermissionEnvironment.swift       # Environment key + empty default

Modules/Sources/Yosemite/Model/Extensions/
  User+Roles.swift                         # MODIFY: add posCashier, posManager

Modules/Sources/Experiments/
  FeatureFlag.swift                         # MODIFY: add posLocalRoles, posRemoteRoles

Modules/Sources/PointOfSale/
  Protocols/POSDependencyProviding.swift    # MODIFY: add permissions
  Utils/POSEnvironmentKeys.swift           # MODIFY: add posPermissions
  Models/PointOfSaleAggregateModel.swift   # MODIFY: integrate permission provider
  Presentation/PointOfSaleEntryPointView.swift  # MODIFY: wrap with lock screen
  Presentation/POSFloatingControlView.swift     # MODIFY: add Lock POS, gate Exit POS
  Presentation/Settings/POSSettingsView.swift   # MODIFY: add Staff section
  Presentation/Orders/POSOrderDetailsView.swift # MODIFY: gate refund with override

WooCommerce/Classes/Authentication/
  RoleErrorViewModel.swift                 # MODIFY: tailored POS role error
  Navigation Exceptions/RoleErrorViewController.swift  # Check for changes needed

WooCommerce/Classes/POS/
  Adaptors/POSPermissionAdaptor.swift      # NEW: bridges app-target to module protocol

Modules/Tests/PointOfSaleTests/
  Roles/
    POSOperatorTests.swift
    LocalPOSPermissionProviderTests.swift
    RemotePOSPermissionProviderTests.swift
    POSPINServiceTests.swift
    MockPOSPermissionProvider.swift
```

---

## Task 1: Feature flags and role eligibility

**Files:**
- Modify: `Modules/Sources/Experiments/FeatureFlag.swift`
- Modify: `Modules/Sources/Yosemite/Model/Extensions/User+Roles.swift`
- Modify: `WooCommerce/Classes/Authentication/Navigation Exceptions/RoleErrorViewModel.swift`
- Test: `Modules/Tests/YosemiteTests/Model/Extensions/User+RolesTests.swift`

- [ ] **Step 1: Add feature flags**

In `Modules/Sources/Experiments/FeatureFlag.swift`, add after the `pointOfSaleBookings` case:

```swift
/// Enables local POS roles with on-device PIN management
case pointOfSaleLocalRoles

/// Enables remote POS roles with server-backed PIN auth and Application Passwords
case pointOfSaleRemoteRoles
```

In the `isEnabled` computed property, add both cases returning `false` (disabled by default):

```swift
case .pointOfSaleLocalRoles:
    return false
case .pointOfSaleRemoteRoles:
    return false
```

- [ ] **Step 2: Add POS role cases to User.Role**

In `Modules/Sources/Yosemite/Model/Extensions/User+Roles.swift`, add two new cases to the `Role` enum:

```swift
case posCashier = "pos_cashier"
case posManager = "pos_manager"
```

Add display strings in `displayString()`:

```swift
case .posCashier:
    return NSLocalizedString("user.role.posCashier", value: "POS Cashier", comment: "User's POS Cashier role.")
case .posManager:
    return NSLocalizedString("user.role.posManager", value: "POS Manager", comment: "User's POS Manager role.")
```

Do NOT add them to `eligibleRoles`. They remain ineligible for app login.

- [ ] **Step 3: Add tailored error for POS roles**

Read `WooCommerce/Classes/Authentication/Navigation Exceptions/RoleErrorViewModel.swift` to understand the current error UI. Add a computed property to detect POS roles and show a tailored message. The `StorageEligibilityErrorInfo` already carries role strings, so check if any role is `pos_cashier` or `pos_manager`:

```swift
var isPOSOnlyRole: Bool {
    roles.contains("pos_cashier") || roles.contains("pos_manager")
}
```

Update the displayed text to use:
- Title: "This account is set up for POS use only"
- Body: "POS accounts can only be used at the point of sale. Ask your store manager to sign you in on the POS device, or log in with a different account."
- Primary button: "Log In With Another Account" (instead of "Retry")

- [ ] **Step 4: Write tests for role eligibility**

In `Modules/Tests/YosemiteTests/Model/Extensions/User+RolesTests.swift`, add tests:

```swift
func test_posCashier_role_is_not_eligible() {
    // Given
    let role = User.Role.posCashier

    // When / Then
    XCTAssertFalse(role.isEligible())
}

func test_posManager_role_is_not_eligible() {
    // Given
    let role = User.Role.posManager

    // When / Then
    XCTAssertFalse(role.isEligible())
}

func test_posCashier_displayString() {
    XCTAssertEqual(User.Role.posCashier.displayString(), "POS Cashier")
}

func test_posManager_displayString() {
    XCTAssertEqual(User.Role.posManager.displayString(), "POS Manager")
}
```

- [ ] **Step 5: Run tests**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme Yosemite \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"YosemiteTests/UserRolesTests"
```

- [ ] **Step 6: Commit**

```bash
git add Modules/Sources/Experiments/FeatureFlag.swift \
       Modules/Sources/Yosemite/Model/Extensions/User+Roles.swift \
       WooCommerce/Classes/Authentication/Navigation\ Exceptions/RoleErrorViewModel.swift \
       Modules/Tests/YosemiteTests/Model/Extensions/User+RolesTests.swift
git commit -m "Add POS role feature flags and login gate for pos_cashier/pos_manager"
```

---

## Task 2: Permission model and shared protocol

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Models/POSOperator.swift`
- Create: `Modules/Sources/PointOfSale/Roles/Models/POSPermissionResult.swift`
- Create: `Modules/Sources/PointOfSale/Roles/Providers/POSPermissionProviding.swift`
- Create: `Modules/Sources/PointOfSale/Roles/Environment/POSPermissionEnvironment.swift`
- Modify: `Modules/Sources/PointOfSale/Protocols/POSDependencyProviding.swift`
- Test: `Modules/Tests/PointOfSaleTests/Roles/POSOperatorTests.swift`

- [ ] **Step 1: Create POSOperator model**

```swift
// Modules/Sources/PointOfSale/Roles/Models/POSOperator.swift
import Foundation

/// Represents the currently active POS operator (the person using the register).
public struct POSOperator: Equatable, Sendable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let capabilities: Set<String>
    /// True if this operator is the WP-authenticated app account holder.
    public let isAppAccountHolder: Bool

    public init(userID: Int64,
                displayName: String,
                role: String,
                capabilities: Set<String>,
                isAppAccountHolder: Bool) {
        self.userID = userID
        self.displayName = displayName
        self.role = role
        self.capabilities = capabilities
        self.isAppAccountHolder = isAppAccountHolder
    }

    public func hasCapability(_ capability: String) -> Bool {
        capabilities.contains(capability)
    }

    public var initials: String {
        let components = displayName.split(separator: " ")
        switch components.count {
        case 0: return "?"
        case 1: return String(components[0].prefix(1)).uppercased()
        default:
            let first = components[0].prefix(1)
            let last = components[components.count - 1].prefix(1)
            return "\(first)\(last)".uppercased()
        }
    }
}
```

- [ ] **Step 2: Create POSPermissionResult**

```swift
// Modules/Sources/PointOfSale/Roles/Models/POSPermissionResult.swift
import Foundation

/// Result of checking a POS permission.
public enum POSPermissionResult: Equatable, Sendable {
    /// The current operator has this capability.
    case allowed
    /// The current operator lacks this capability - manager override can authorize.
    case requiresOverride
}
```

- [ ] **Step 3: Create POSPermissionProviding protocol**

```swift
// Modules/Sources/PointOfSale/Roles/Providers/POSPermissionProviding.swift
import Foundation

/// Shared protocol for POS permission checking.
/// Two implementations: LocalPOSPermissionProvider, RemotePOSPermissionProvider.
/// All POS views use this protocol via @Environment(\.posPermissions).
public protocol POSPermissionProviding: AnyObject {
    /// The currently active POS operator (nil = no one signed in, show lock screen).
    var currentOperator: POSOperator? { get }

    /// Whether POS is locked (requires PIN to access).
    var isLocked: Bool { get }

    /// Check a capability against the current operator.
    /// Returns .allowed if the operator has the capability,
    /// .requiresOverride if they don't (and manager can authorize).
    func checkPermission(_ capability: String) -> POSPermissionResult

    /// Shorthand: returns true if checkPermission returns .allowed.
    func hasCapability(_ capability: String) -> Bool

    /// Sign in an operator after PIN verification.
    func signIn(_ operator: POSOperator)

    /// Lock POS (clear current operator, show PIN screen).
    func lock()
}
```

- [ ] **Step 4: Create environment key**

```swift
// Modules/Sources/PointOfSale/Roles/Environment/POSPermissionEnvironment.swift
import SwiftUI

struct POSPermissionsKey: EnvironmentKey {
    static let defaultValue: POSPermissionProviding = EmptyPOSPermissionProvider()
}

extension EnvironmentValues {
    var posPermissions: POSPermissionProviding {
        get { self[POSPermissionsKey.self] }
        set { self[POSPermissionsKey.self] = newValue }
    }
}

/// Default no-op provider when roles are disabled.
/// All permissions are allowed, no lock screen, no operator tracking.
final class EmptyPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator? { nil }
    var isLocked: Bool { false }
    func checkPermission(_ capability: String) -> POSPermissionResult { .allowed }
    func hasCapability(_ capability: String) -> Bool { true }
    func signIn(_ operator: POSOperator) {}
    func lock() {}
}
```

- [ ] **Step 5: Add permissions to POSDependencyProviding**

In `Modules/Sources/PointOfSale/Protocols/POSDependencyProviding.swift`, add to the `POSDependencyProviding` protocol:

```swift
var permissions: POSPermissionProviding { get }
```

- [ ] **Step 6: Write POSOperator tests**

```swift
// Modules/Tests/PointOfSaleTests/Roles/POSOperatorTests.swift
import Testing
@testable import PointOfSale

struct POSOperatorTests {
    @Test func test_hasCapability_returns_true_when_present() {
        // Given
        let op = POSOperator(userID: 1, displayName: "Jane",
                             role: "pos_cashier",
                             capabilities: ["woocommerce_pos_access"],
                             isAppAccountHolder: false)
        // When / Then
        #expect(op.hasCapability("woocommerce_pos_access") == true)
    }

    @Test func test_hasCapability_returns_false_when_absent() {
        let op = POSOperator(userID: 1, displayName: "Jane",
                             role: "pos_cashier",
                             capabilities: ["woocommerce_pos_access"],
                             isAppAccountHolder: false)
        #expect(op.hasCapability("woocommerce_refund_orders") == false)
    }

    @Test func test_initials_from_full_name() {
        let op = POSOperator(userID: 1, displayName: "Jane Doe",
                             role: "pos_cashier", capabilities: [],
                             isAppAccountHolder: false)
        #expect(op.initials == "JD")
    }

    @Test func test_initials_from_single_name() {
        let op = POSOperator(userID: 1, displayName: "Jane",
                             role: "pos_cashier", capabilities: [],
                             isAppAccountHolder: false)
        #expect(op.initials == "J")
    }
}
```

- [ ] **Step 7: Run tests**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests/POSOperatorTests"
```

- [ ] **Step 8: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/ \
       Modules/Sources/PointOfSale/Protocols/POSDependencyProviding.swift \
       Modules/Tests/PointOfSaleTests/Roles/
git commit -m "Add POS permission model, protocol, and environment key"
```

---

## Task 3: Local permission provider

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Providers/LocalPOSPermissionProvider.swift`
- Create: `Modules/Sources/PointOfSale/Roles/Services/POSPINService.swift`
- Test: `Modules/Tests/PointOfSaleTests/Roles/LocalPOSPermissionProviderTests.swift`
- Test: `Modules/Tests/PointOfSaleTests/Roles/POSPINServiceTests.swift`

- [ ] **Step 1: Create POSPINService for local PIN management**

```swift
// Modules/Sources/PointOfSale/Roles/Services/POSPINService.swift
import Foundation
import Security

/// Manages POS PINs in the iOS Keychain for local role implementation.
/// Stores hashed PINs for Manager and Cashier roles.
public final class POSPINService {
    private let keychainService = "com.woocommerce.pos.pins"

    enum PINRole: String {
        case manager
        case cashier
    }

    func setPIN(_ pin: String, for role: PINRole) {
        let data = hashPIN(pin).data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: role.rawValue,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func verifyPIN(_ pin: String, for role: PINRole) -> Bool {
        guard let storedHash = getStoredHash(for: role) else { return false }
        return hashPIN(pin) == storedHash
    }

    func hasPIN(for role: PINRole) -> Bool {
        getStoredHash(for: role) != nil
    }

    func deletePIN(for role: PINRole) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: role.rawValue
        ]
        SecItemDelete(query as CFDictionary)
    }

    /// Validates PIN format: 4-6 numeric digits.
    func isValidFormat(_ pin: String) -> Bool {
        let pattern = /^\d{4,6}$/
        return pin.wholeMatch(of: pattern) != nil
    }

    /// Verifies a PIN against all roles and returns the matching role, if any.
    func verifyPIN(_ pin: String) -> PINRole? {
        for role in [PINRole.manager, .cashier] {
            if verifyPIN(pin, for: role) {
                return role
            }
        }
        return nil
    }

    private func hashPIN(_ pin: String) -> String {
        let data = Data(pin.utf8)
        var hash = [UInt8](repeating: 0, count: 32)
        data.withUnsafeBytes { buffer in
            CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    private func getStoredHash(for role: PINRole) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: role.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
```

Note: This uses `CC_SHA256` from CommonCrypto. Add `import CommonCrypto` or use `CryptoKit` instead:

```swift
import CryptoKit

private func hashPIN(_ pin: String) -> String {
    let data = Data(pin.utf8)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
}
```

- [ ] **Step 2: Create LocalPOSPermissionProvider**

```swift
// Modules/Sources/PointOfSale/Roles/Providers/LocalPOSPermissionProvider.swift
import Foundation
import Observation

/// Local implementation of POSPermissionProviding.
/// Uses on-device PINs (Manager/Cashier) with hardcoded capability sets.
@Observable
public final class LocalPOSPermissionProvider: POSPermissionProviding {
    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool = false

    private let pinService: POSPINService
    /// The WP-authenticated app user ID (for isAppAccountHolder flag on exit).
    private let appAccountUserID: Int64
    private let appAccountDisplayName: String

    static let managerCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_pos_manage_settings",
        "woocommerce_void_orders",
        "woocommerce_refund_orders",
        "woocommerce_apply_discounts",
        "woocommerce_override_prices",
        "woocommerce_view_sales_reports",
        "woocommerce_view_personal_sales",
        "woocommerce_approve_overrides",
        "woocommerce_view_customer_data",
        "woocommerce_edit_customer_data",
        "woocommerce_adjust_stock",
        "woocommerce_view_audit_logs",
    ]

    static let cashierCapabilities: Set<String> = [
        "woocommerce_pos_access",
        "woocommerce_view_personal_sales",
        "woocommerce_view_customer_data",
    ]

    public init(pinService: POSPINService,
                appAccountUserID: Int64,
                appAccountDisplayName: String) {
        self.pinService = pinService
        self.appAccountUserID = appAccountUserID
        self.appAccountDisplayName = appAccountDisplayName
    }

    public func checkPermission(_ capability: String) -> POSPermissionResult {
        guard isLocked, let op = currentOperator else {
            return .allowed
        }
        return op.hasCapability(capability) ? .allowed : .requiresOverride
    }

    public func hasCapability(_ capability: String) -> Bool {
        checkPermission(capability) == .allowed
    }

    public func signIn(_ op: POSOperator) {
        currentOperator = op
        isLocked = true
    }

    public func lock() {
        currentOperator = nil
        isLocked = true
    }

    /// Authenticate a PIN and sign in the matching role.
    /// Returns the matched operator, or nil if PIN is invalid.
    public func authenticatePIN(_ pin: String) -> POSOperator? {
        guard let role = pinService.verifyPIN(pin) else { return nil }

        let capabilities: Set<String>
        let roleName: String
        let isAccountHolder: Bool

        switch role {
        case .manager:
            capabilities = Self.managerCapabilities
            roleName = "pos_manager"
            isAccountHolder = true
        case .cashier:
            capabilities = Self.cashierCapabilities
            roleName = "pos_cashier"
            isAccountHolder = false
        }

        let op = POSOperator(
            userID: isAccountHolder ? appAccountUserID : 0,
            displayName: isAccountHolder ? appAccountDisplayName : NSLocalizedString(
                "pos.local.cashier.name",
                value: "Cashier",
                comment: "Default display name for the local POS cashier role"),
            role: roleName,
            capabilities: capabilities,
            isAppAccountHolder: isAccountHolder
        )
        signIn(op)
        return op
    }

    /// Verify a manager PIN for override approval (local mode).
    /// Returns true if the PIN matches the manager role.
    public func verifyManagerPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }

    /// Verify the app account holder's PIN for Exit POS.
    public func verifyAccountHolderPIN(_ pin: String) -> Bool {
        pinService.verifyPIN(pin, for: .manager)
    }

    /// Whether any PINs are configured (roles are active).
    public var hasAnyPINs: Bool {
        pinService.hasPIN(for: .manager) || pinService.hasPIN(for: .cashier)
    }
}
```

- [ ] **Step 3: Write tests**

```swift
// Modules/Tests/PointOfSaleTests/Roles/LocalPOSPermissionProviderTests.swift
import Testing
@testable import PointOfSale

struct LocalPOSPermissionProviderTests {
    private func makePINService() -> POSPINService {
        POSPINService()
    }

    private func makeProvider(pinService: POSPINService? = nil) -> LocalPOSPermissionProvider {
        let service = pinService ?? makePINService()
        return LocalPOSPermissionProvider(
            pinService: service,
            appAccountUserID: 1,
            appAccountDisplayName: "Alice"
        )
    }

    @Test func test_checkPermission_returns_allowed_when_not_locked() {
        let provider = makeProvider()
        #expect(provider.checkPermission("woocommerce_refund_orders") == .allowed)
    }

    @Test func test_checkPermission_returns_allowed_for_manager_capability() {
        let provider = makeProvider()
        let op = POSOperator(userID: 1, displayName: "Alice", role: "pos_manager",
                             capabilities: LocalPOSPermissionProvider.managerCapabilities,
                             isAppAccountHolder: true)
        provider.signIn(op)
        #expect(provider.checkPermission("woocommerce_refund_orders") == .allowed)
    }

    @Test func test_checkPermission_returns_requiresOverride_for_cashier_missing_capability() {
        let provider = makeProvider()
        let op = POSOperator(userID: 2, displayName: "Jane", role: "pos_cashier",
                             capabilities: LocalPOSPermissionProvider.cashierCapabilities,
                             isAppAccountHolder: false)
        provider.signIn(op)
        #expect(provider.checkPermission("woocommerce_refund_orders") == .requiresOverride)
    }

    @Test func test_lock_clears_operator_and_sets_locked() {
        let provider = makeProvider()
        let op = POSOperator(userID: 1, displayName: "Alice", role: "pos_manager",
                             capabilities: LocalPOSPermissionProvider.managerCapabilities,
                             isAppAccountHolder: true)
        provider.signIn(op)
        provider.lock()
        #expect(provider.currentOperator == nil)
        #expect(provider.isLocked == true)
    }

    @Test func test_authenticatePIN_with_valid_manager_pin() {
        let service = makePINService()
        service.setPIN("1234", for: .manager)
        let provider = makeProvider(pinService: service)
        provider.lock()

        let op = provider.authenticatePIN("1234")
        #expect(op != nil)
        #expect(op?.role == "pos_manager")
        #expect(op?.isAppAccountHolder == true)

        // Cleanup
        service.deletePIN(for: .manager)
    }

    @Test func test_authenticatePIN_with_invalid_pin() {
        let service = makePINService()
        service.setPIN("1234", for: .manager)
        let provider = makeProvider(pinService: service)
        provider.lock()

        let op = provider.authenticatePIN("9999")
        #expect(op == nil)

        service.deletePIN(for: .manager)
    }
}
```

- [ ] **Step 4: Run tests**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests/LocalPOSPermissionProviderTests"
```

- [ ] **Step 5: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Providers/LocalPOSPermissionProvider.swift \
       Modules/Sources/PointOfSale/Roles/Services/POSPINService.swift \
       Modules/Tests/PointOfSaleTests/Roles/
git commit -m "Add local POS permission provider with Keychain PIN service"
```

---

## Task 4: Remote permission provider

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Providers/RemotePOSPermissionProvider.swift`
- Create: `Modules/Sources/PointOfSale/Roles/Services/POSApprovalService.swift`
- Test: `Modules/Tests/PointOfSaleTests/Roles/RemotePOSPermissionProviderTests.swift`
- Test: `Modules/Tests/PointOfSaleTests/Roles/MockPOSPermissionProvider.swift`

- [ ] **Step 1: Create RemotePOSPermissionProvider**

This provider calls the backend REST API endpoints:
- `POST /wc/v3/pos/auth/pin` - validate PIN, get Application Password + capabilities
- `POST /wc/v3/pos/auth/approve` - manager override, get approval token
- `GET /wc/v3/pos/auth/pin/status` - list staff with PIN status

The provider needs a Yosemite action or a Networking Remote to make these calls. Create it using the existing POS networking pattern (via Yosemite actions dispatched through stores).

```swift
// Modules/Sources/PointOfSale/Roles/Providers/RemotePOSPermissionProvider.swift
import Foundation
import Observation

/// Remote implementation of POSPermissionProviding.
/// Uses backend REST API for PIN auth, capabilities, and approval tokens.
@Observable
public final class RemotePOSPermissionProvider: POSPermissionProviding {
    public private(set) var currentOperator: POSOperator?
    public private(set) var isLocked: Bool = false

    /// Cached capabilities from last PIN auth response.
    private var cachedCapabilities: Set<String> = []

    /// The Application Password credential for the current POS session.
    private(set) var sessionCredential: POSSessionCredential?

    /// Service for making approval requests.
    private let approvalService: POSApprovalServiceProtocol

    /// Closure to perform PIN authentication against the backend.
    /// Injected to decouple from networking layer.
    private let authenticatePIN: (String, String) async throws -> POSPINAuthResponse

    /// The app account user ID.
    private let appAccountUserID: Int64

    public init(appAccountUserID: Int64,
                authenticatePIN: @escaping (String, String) async throws -> POSPINAuthResponse,
                approvalService: POSApprovalServiceProtocol) {
        self.appAccountUserID = appAccountUserID
        self.authenticatePIN = authenticatePIN
        self.approvalService = approvalService
    }

    public func checkPermission(_ capability: String) -> POSPermissionResult {
        guard isLocked, currentOperator != nil else {
            return .allowed
        }
        return cachedCapabilities.contains(capability) ? .allowed : .requiresOverride
    }

    public func hasCapability(_ capability: String) -> Bool {
        checkPermission(capability) == .allowed
    }

    public func signIn(_ op: POSOperator) {
        currentOperator = op
        cachedCapabilities = op.capabilities
        isLocked = true
    }

    public func lock() {
        currentOperator = nil
        cachedCapabilities = []
        isLocked = true
    }

    /// Authenticate via backend PIN endpoint.
    public func authenticateRemotePIN(_ pin: String, registerID: String = "default") async throws -> POSOperator {
        let response = try await authenticatePIN(pin, registerID)
        let caps = Set(response.capabilities.filter { $0.value }.map(\.key))
        let op = POSOperator(
            userID: response.userID,
            displayName: response.displayName,
            role: response.role,
            capabilities: caps,
            isAppAccountHolder: response.userID == appAccountUserID
        )
        sessionCredential = POSSessionCredential(
            applicationPassword: response.applicationPassword,
            uuid: response.applicationPasswordUUID,
            sessionExpires: response.sessionExpires,
            idleTimeoutSeconds: response.idleTimeoutSeconds
        )
        signIn(op)
        return op
    }

    /// Request manager approval for a restricted action.
    public func requestApproval(managerPIN: String,
                                action: String,
                                orderID: Int64) async throws -> String {
        try await approvalService.requestApproval(
            pin: managerPIN,
            action: action,
            context: ["order_id": orderID]
        )
    }
}

/// Response from POST /wc/v3/pos/auth/pin
public struct POSPINAuthResponse: Decodable {
    public let userID: Int64
    public let displayName: String
    public let role: String
    public let capabilities: [String: Bool]
    public let applicationPassword: String
    public let applicationPasswordUUID: String
    public let sessionExpires: String
    public let idleTimeoutSeconds: Int

    private enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case role
        case capabilities
        case applicationPassword = "application_password"
        case applicationPasswordUUID = "application_password_uuid"
        case sessionExpires = "session_expires"
        case idleTimeoutSeconds = "idle_timeout_seconds"
    }
}

/// Stored credential for the active POS session.
public struct POSSessionCredential {
    public let applicationPassword: String
    public let uuid: String
    public let sessionExpires: String
    public let idleTimeoutSeconds: Int
}
```

- [ ] **Step 2: Create POSApprovalService**

```swift
// Modules/Sources/PointOfSale/Roles/Services/POSApprovalService.swift
import Foundation

public protocol POSApprovalServiceProtocol {
    func requestApproval(pin: String, action: String, context: [String: Any]) async throws -> String
}

/// Response from POST /wc/v3/pos/auth/approve
public struct POSApprovalResponse: Decodable {
    public let approved: Bool
    public let approverID: Int64
    public let approverName: String
    public let approvalToken: String
    public let expiresIn: Int

    private enum CodingKeys: String, CodingKey {
        case approved
        case approverID = "approver_id"
        case approverName = "approver_name"
        case approvalToken = "approval_token"
        case expiresIn = "expires_in"
    }
}
```

The concrete implementation of `POSApprovalServiceProtocol` will live in the app target (`WooCommerce/Classes/POS/Adaptors/`) since it depends on Networking/Yosemite. For now, the module defines the protocol and response types.

- [ ] **Step 3: Create MockPOSPermissionProvider for tests**

```swift
// Modules/Tests/PointOfSaleTests/Roles/MockPOSPermissionProvider.swift
@testable import PointOfSale

final class MockPOSPermissionProvider: POSPermissionProviding {
    var currentOperator: POSOperator?
    var isLocked: Bool = false
    var capabilityOverrides: [String: POSPermissionResult] = [:]

    func checkPermission(_ capability: String) -> POSPermissionResult {
        capabilityOverrides[capability] ?? .allowed
    }

    func hasCapability(_ capability: String) -> Bool {
        checkPermission(capability) == .allowed
    }

    func signIn(_ op: POSOperator) {
        currentOperator = op
        isLocked = true
    }

    func lock() {
        currentOperator = nil
        isLocked = true
    }
}
```

- [ ] **Step 4: Write tests**

```swift
// Modules/Tests/PointOfSaleTests/Roles/RemotePOSPermissionProviderTests.swift
import Testing
@testable import PointOfSale

struct RemotePOSPermissionProviderTests {
    @Test func test_authenticateRemotePIN_sets_operator_and_capabilities() async throws {
        let response = POSPINAuthResponse(
            userID: 42, displayName: "Jane", role: "pos_cashier",
            capabilities: ["woocommerce_pos_access": true, "woocommerce_view_personal_sales": true],
            applicationPassword: "test-pass", applicationPasswordUUID: "uuid-1",
            sessionExpires: "2026-04-10T00:00:00Z", idleTimeoutSeconds: 1800
        )
        let provider = RemotePOSPermissionProvider(
            appAccountUserID: 1,
            authenticatePIN: { _, _ in response },
            approvalService: MockApprovalService()
        )
        provider.lock()

        let op = try await provider.authenticateRemotePIN("1234")
        #expect(op.userID == 42)
        #expect(op.role == "pos_cashier")
        #expect(op.isAppAccountHolder == false)
        #expect(provider.hasCapability("woocommerce_pos_access") == true)
        #expect(provider.hasCapability("woocommerce_refund_orders") == false)
        #expect(provider.checkPermission("woocommerce_refund_orders") == .requiresOverride)
    }

    @Test func test_app_account_holder_detected() async throws {
        let response = POSPINAuthResponse(
            userID: 1, displayName: "Alice", role: "administrator",
            capabilities: ["woocommerce_pos_access": true, "woocommerce_refund_orders": true],
            applicationPassword: "test-pass", applicationPasswordUUID: "uuid-1",
            sessionExpires: "2026-04-10T00:00:00Z", idleTimeoutSeconds: 1800
        )
        let provider = RemotePOSPermissionProvider(
            appAccountUserID: 1,
            authenticatePIN: { _, _ in response },
            approvalService: MockApprovalService()
        )
        provider.lock()

        let op = try await provider.authenticateRemotePIN("9999")
        #expect(op.isAppAccountHolder == true)
    }
}

private struct MockApprovalService: POSApprovalServiceProtocol {
    func requestApproval(pin: String, action: String, context: [String: Any]) async throws -> String {
        "mock-token"
    }
}
```

- [ ] **Step 5: Run tests**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests/RemotePOSPermissionProviderTests"
```

- [ ] **Step 6: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Providers/RemotePOSPermissionProvider.swift \
       Modules/Sources/PointOfSale/Roles/Services/POSApprovalService.swift \
       Modules/Tests/PointOfSaleTests/Roles/
git commit -m "Add remote POS permission provider with REST API integration"
```

---

## Task 5: PIN entry view

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Views/POSPINEntryView.swift`

- [ ] **Step 1: Create the PIN entry numpad view**

This is a reusable component used by lock screen, manager override, and exit POS. Full-screen numpad following POS design tokens (POSSpacing, POSPadding, POSFontStyle, Color+POSColorPalette). iPad-centered layout. Big buttons per POS UX principles.

```swift
// Modules/Sources/PointOfSale/Roles/Views/POSPINEntryView.swift
import SwiftUI

struct POSPINEntryView: View {
    let title: String
    let subtitle: String?
    let onPINEntered: (String) -> Void
    let onCancel: (() -> Void)?

    @State private var enteredPIN: String = ""
    @State private var isShaking: Bool = false
    @State private var errorMessage: String?
    @State private var isDisabled: Bool = false

    private let pinLength: Int = 4

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Spacer()

            // Title
            Text(title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)

            if let subtitle {
                Text(subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantLowest)
            }

            // PIN dots
            HStack(spacing: POSSpacing.medium) {
                ForEach(0..<pinLength, id: \.self) { index in
                    Circle()
                        .fill(index < enteredPIN.count ? Color.posPrimary : Color.posOutline)
                        .frame(width: 16, height: 16)
                }
            }
            .modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
            .padding(.vertical, POSPadding.medium)

            // Error message
            if let errorMessage {
                Text(errorMessage)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posError)
            }

            // Numpad
            VStack(spacing: POSSpacing.small) {
                ForEach(0..<3) { row in
                    HStack(spacing: POSSpacing.small) {
                        ForEach(1...3, id: \.self) { col in
                            let digit = row * 3 + col
                            numpadButton(String(digit))
                        }
                    }
                }
                HStack(spacing: POSSpacing.small) {
                    // Empty spacer on left
                    Color.clear.frame(width: Constants.buttonSize, height: Constants.buttonSize)

                    numpadButton("0")

                    // Delete button
                    Button {
                        guard !enteredPIN.isEmpty else { return }
                        enteredPIN.removeLast()
                        errorMessage = nil
                    } label: {
                        Image(systemName: "delete.backward")
                            .font(.posBodyLargeBold)
                            .foregroundColor(.posOnSurface)
                            .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    }
                    .disabled(isDisabled)
                }
            }

            Spacer()

            // Cancel / bottom action
            if let onCancel {
                Button {
                    onCancel()
                } label: {
                    Text(Localization.cancel)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
            }
        }
        .padding(POSPadding.xLarge)
        .frame(maxWidth: 400)
        .background(Color.posSurfaceDim)
    }

    @ViewBuilder
    private func numpadButton(_ digit: String) -> some View {
        Button {
            guard enteredPIN.count < pinLength, !isDisabled else { return }
            enteredPIN.append(digit)
            errorMessage = nil
            if enteredPIN.count == pinLength {
                onPINEntered(enteredPIN)
            }
        } label: {
            Text(digit)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                .background(Color.posSurfaceContainerLow)
                .cornerRadius(Constants.buttonCornerRadius)
        }
        .disabled(isDisabled)
    }

    /// Call from parent to indicate wrong PIN.
    func showError(_ message: String) {
        errorMessage = message
        enteredPIN = ""
        withAnimation(.default) {
            isShaking = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isShaking = false
        }
    }

    /// Call from parent to indicate lockout.
    func showLockout(seconds: Int) {
        isDisabled = true
        errorMessage = String(format: Localization.lockoutFormat, seconds)
        enteredPIN = ""
    }

    func reset() {
        enteredPIN = ""
        errorMessage = nil
        isDisabled = false
    }
}

private extension POSPINEntryView {
    enum Constants {
        static let buttonSize: CGFloat = 72
        static let buttonCornerRadius: CGFloat = 16
    }

    enum Localization {
        static let cancel = NSLocalizedString(
            "pos.pin.cancel",
            value: "Cancel",
            comment: "Cancel button on POS PIN entry screen")
        static let lockoutFormat = NSLocalizedString(
            "pos.pin.lockout",
            value: "Too many attempts. Try again in %d seconds.",
            comment: "Lockout message on POS PIN entry. %1$d is seconds remaining.")
    }
}

/// Shake animation modifier for wrong PIN.
struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = sin(animatableData * .pi * 4) * 10
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

#if DEBUG
#Preview("PIN Entry") {
    POSPINEntryView(
        title: "Enter PIN",
        subtitle: "Enter your 4-digit PIN to continue",
        onPINEntered: { pin in print("PIN: \(pin)") },
        onCancel: {}
    )
}
#endif
```

- [ ] **Step 2: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Views/POSPINEntryView.swift
git commit -m "Add POS PIN entry numpad view with shake animation"
```

---

## Task 6: Lock screen view

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Views/POSLockScreenView.swift`

- [ ] **Step 1: Create the lock screen**

Full-screen lock screen with PIN entry and "Log in with a different account" link (following Shopify pattern).

```swift
// Modules/Sources/PointOfSale/Roles/Views/POSLockScreenView.swift
import SwiftUI

struct POSLockScreenView: View {
    @Environment(\.posPermissions) private var permissions
    @Environment(\.posAnalytics) private var analytics

    let onAuthenticated: (POSOperator) -> Void
    let onLogout: () -> Void

    @State private var errorMessage: String?
    @State private var failureCount: Int = 0
    @State private var lockoutEndDate: Date?

    var body: some View {
        ZStack {
            Color.posSurfaceDim.ignoresSafeArea()

            POSPINEntryView(
                title: Localization.title,
                subtitle: Localization.subtitle,
                onPINEntered: { pin in
                    handlePINEntry(pin)
                },
                onCancel: nil
            )
            .overlay(alignment: .bottom) {
                Button {
                    onLogout()
                } label: {
                    Text(Localization.loginWithDifferentAccount)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)
                        .underline()
                }
                .padding(.bottom, POSPadding.xLarge)
            }
        }
    }

    private func handlePINEntry(_ pin: String) {
        // TODO: This will be wired to the actual permission provider
        // For now this is a placeholder that the integration task will complete
    }
}

private extension POSLockScreenView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.title",
            value: "Enter PIN",
            comment: "Title on POS lock screen")
        static let subtitle = NSLocalizedString(
            "pos.lockScreen.subtitle",
            value: "Enter your PIN to access the point of sale",
            comment: "Subtitle on POS lock screen")
        static let loginWithDifferentAccount = NSLocalizedString(
            "pos.lockScreen.loginWithDifferentAccount",
            value: "Log in with a different account",
            comment: "Link at bottom of POS lock screen to switch WP accounts, following Shopify pattern")
    }
}

#if DEBUG
#Preview("Lock Screen") {
    POSLockScreenView(
        onAuthenticated: { op in print("Authenticated: \(op.displayName)") },
        onLogout: { print("Logout") }
    )
}
#endif
```

- [ ] **Step 2: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Views/POSLockScreenView.swift
git commit -m "Add POS lock screen with PIN entry and logout link"
```

---

## Task 7: Manager override view

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Views/POSManagerOverrideView.swift`

- [ ] **Step 1: Create manager override modal**

Modal overlay following POS modal patterns. Shows the action description, PIN numpad, and handles approval flow for both local and remote providers.

```swift
// Modules/Sources/PointOfSale/Roles/Views/POSManagerOverrideView.swift
import SwiftUI

struct POSManagerOverrideView: View {
    let actionDescription: String
    let capability: String
    let onApproved: (String?) -> Void  // approval token (remote) or nil (local)
    let onCancelled: () -> Void

    @Environment(\.posPermissions) private var permissions
    @Environment(\.posAnalytics) private var analytics

    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            // Header
            HStack {
                Spacer()
                Button {
                    onCancelled()
                } label: {
                    Image(systemName: "xmark")
                        .font(.posButtonSymbolLarge)
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
            }

            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.posPrimary)

            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)

            Text(actionDescription)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurfaceVariantLowest)
                .multilineTextAlignment(.center)

            POSPINEntryView(
                title: Localization.pinPrompt,
                subtitle: nil,
                onPINEntered: { pin in
                    handleManagerPIN(pin)
                },
                onCancel: { onCancelled() }
            )
        }
        .padding(POSPadding.xLarge)
        .background(Color.posSurface)
        .cornerRadius(POSCornerRadiusStyle.large.value)
    }

    private func handleManagerPIN(_ pin: String) {
        // Wired during integration - calls provider's approval method
    }
}

private extension POSManagerOverrideView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.managerOverride.title",
            value: "Manager approval required",
            comment: "Title of manager override modal in POS")
        static let pinPrompt = NSLocalizedString(
            "pos.managerOverride.pinPrompt",
            value: "Enter manager PIN",
            comment: "Prompt for manager to enter their PIN for override approval")
    }
}

#if DEBUG
#Preview("Manager Override") {
    POSManagerOverrideView(
        actionDescription: "Process refund for Order #123",
        capability: "woocommerce_refund_orders",
        onApproved: { _ in },
        onCancelled: {}
    )
}
#endif
```

- [ ] **Step 2: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Views/POSManagerOverrideView.swift
git commit -m "Add POS manager override modal view"
```

---

## Task 8: Staff settings view (local mode)

**Files:**
- Create: `Modules/Sources/PointOfSale/Roles/Views/POSStaffSettingsView.swift`
- Modify: `Modules/Sources/PointOfSale/Presentation/Settings/POSSettingsView.swift`

- [ ] **Step 1: Create staff settings view**

Simple view for local mode: set/change Manager PIN and Cashier PIN. For remote mode: shows staff list from backend.

```swift
// Modules/Sources/PointOfSale/Roles/Views/POSStaffSettingsView.swift
import SwiftUI

struct POSStaffSettingsView: View {
    @Environment(\.posPermissions) private var permissions
    @Environment(\.posAnalytics) private var analytics

    @State private var managerPIN: String = ""
    @State private var cashierPIN: String = ""
    @State private var showManagerPINEntry: Bool = false
    @State private var showCashierPINEntry: Bool = false
    @State private var confirmationMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.large) {
            POSPageHeaderView(title: Localization.title)
                .foregroundColor(.posSurface)
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: POSSpacing.medium) {
                // Manager PIN
                pinRow(
                    title: Localization.managerPIN,
                    subtitle: Localization.managerPINDescription,
                    isSet: false, // Will be wired to pinService.hasPIN(.manager)
                    onSetTapped: { showManagerPINEntry = true }
                )

                // Cashier PIN
                pinRow(
                    title: Localization.cashierPIN,
                    subtitle: Localization.cashierPINDescription,
                    isSet: false, // Will be wired to pinService.hasPIN(.cashier)
                    onSetTapped: { showCashierPINEntry = true }
                )
            }

            if let confirmationMessage {
                Text(confirmationMessage)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posSuccess)
            }

            Spacer()
        }
        .padding(.horizontal, POSPadding.medium)
        .background(Color.posSurfaceBright)
    }

    @ViewBuilder
    private func pinRow(title: String, subtitle: String, isSet: Bool, onSetTapped: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            HStack {
                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(title)
                        .font(.posBodyLargeBold)
                        .foregroundColor(.posOnSurface)
                    Text(subtitle)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)
                }
                Spacer()
                Button(isSet ? Localization.changePIN : Localization.setPIN) {
                    onSetTapped()
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .small))
            }
        }
        .padding(POSPadding.medium)
        .background(Color.posSurface)
        .cornerRadius(POSCornerRadiusStyle.medium.value)
    }
}

private extension POSStaffSettingsView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.staffSettings.title",
            value: "Staff",
            comment: "Title of POS staff settings section")
        static let managerPIN = NSLocalizedString(
            "pos.staffSettings.managerPIN",
            value: "Manager PIN",
            comment: "Label for manager PIN setting in POS")
        static let managerPINDescription = NSLocalizedString(
            "pos.staffSettings.managerPINDescription",
            value: "Used to access all POS features and approve restricted actions",
            comment: "Description of what the manager PIN is used for")
        static let cashierPIN = NSLocalizedString(
            "pos.staffSettings.cashierPIN",
            value: "Cashier PIN",
            comment: "Label for cashier PIN setting in POS")
        static let cashierPINDescription = NSLocalizedString(
            "pos.staffSettings.cashierPINDescription",
            value: "Used for basic sales and payments. Restricted actions require manager approval",
            comment: "Description of what the cashier PIN is used for")
        static let setPIN = NSLocalizedString(
            "pos.staffSettings.setPIN",
            value: "Set PIN",
            comment: "Button to set a POS PIN")
        static let changePIN = NSLocalizedString(
            "pos.staffSettings.changePIN",
            value: "Change",
            comment: "Button to change an existing POS PIN")
    }
}
```

- [ ] **Step 2: Add Staff section to POSSettingsView**

In `Modules/Sources/PointOfSale/Presentation/Settings/POSSettingsView.swift`, add a new case to `SidebarNavigation`:

```swift
case staff
```

Add the staff card in the sidebar list view alongside store and hardware. Add the detail view to route to `POSStaffSettingsView`.

- [ ] **Step 3: Commit**

```bash
git add Modules/Sources/PointOfSale/Roles/Views/POSStaffSettingsView.swift \
       Modules/Sources/PointOfSale/Presentation/Settings/POSSettingsView.swift
git commit -m "Add POS staff settings view with PIN management"
```

---

## Task 9: Integration - wire lock screen into POS entry

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift`
- Modify: `Modules/Sources/PointOfSale/Presentation/POSFloatingControlView.swift`
- Modify: `Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift`

- [ ] **Step 1: Add Lock POS menu item and gate Exit POS**

In `POSFloatingControlView.swift`, modify `menuOptions()`:
- Add "Lock POS" menu item that calls `permissions.lock()`
- Modify "Exit POS" to check if POS is locked - if locked, show account holder PIN prompt instead of the regular exit confirmation

- [ ] **Step 2: Wrap entry point with lock screen**

In `PointOfSaleEntryPointView.swift`, add conditional lock screen overlay:
- When `permissions.isLocked && permissions.currentOperator == nil`, show `POSLockScreenView`
- When authenticated, show the normal POS dashboard
- Pass the permission provider via `.environment(\.posPermissions, provider)`

- [ ] **Step 3: Wire permission provider into aggregate model**

In `PointOfSaleAggregateModel.swift`, add a `permissionProvider` property. The entry point view creates the appropriate provider based on feature flags and passes it through.

- [ ] **Step 4: Commit**

```bash
git add Modules/Sources/PointOfSale/Presentation/PointOfSaleEntryPointView.swift \
       Modules/Sources/PointOfSale/Presentation/POSFloatingControlView.swift \
       Modules/Sources/PointOfSale/Models/PointOfSaleAggregateModel.swift
git commit -m "Wire lock screen and permission provider into POS entry point"
```

---

## Task 10: Integration - gate refunds and coupons with override

**Files:**
- Modify: `Modules/Sources/PointOfSale/Presentation/Orders/POSOrderDetailsView.swift`
- Modify: coupon-related views as needed

- [ ] **Step 1: Gate refund action in order details**

In `POSOrderDetailsView.swift`, wrap the refund initiation with a permission check:
- Check `permissions.checkPermission("woocommerce_refund_orders")`
- If `.requiresOverride`, show `POSManagerOverrideView` before proceeding
- If `.allowed`, proceed as today

- [ ] **Step 2: Gate coupon creation**

Find where coupon creation is triggered (via `POSExternalViewProviding.createCouponCreationView`) and wrap with permission check for `woocommerce_apply_discounts`.

- [ ] **Step 3: Commit**

```bash
git add Modules/Sources/PointOfSale/Presentation/Orders/POSOrderDetailsView.swift
git commit -m "Gate refund and coupon creation with permission checks and override"
```

---

## Task 11: App target adaptor - bridge providers to app

**Files:**
- Create: `WooCommerce/Classes/POS/Adaptors/POSPermissionAdaptor.swift`
- Modify: `WooCommerce/Classes/POS/TabBar/POSTabCoordinator.swift`

- [ ] **Step 1: Create adaptor that creates the correct provider based on feature flags**

```swift
// WooCommerce/Classes/POS/Adaptors/POSPermissionAdaptor.swift
import PointOfSale

/// Creates the appropriate POSPermissionProviding implementation based on feature flags.
struct POSPermissionAdaptor {
    static func createProvider(
        siteID: Int64,
        userID: Int64,
        displayName: String,
        featureFlags: POSFeatureFlagProviding
    ) -> POSPermissionProviding {
        if featureFlags.isFeatureFlagEnabled(.pointOfSaleRemoteRoles) {
            return RemotePOSPermissionProvider(
                appAccountUserID: userID,
                authenticatePIN: { pin, registerID in
                    // Wire to Yosemite action or Networking remote
                    // This calls POST /wc/v3/pos/auth/pin
                    fatalError("Wire to networking layer")
                },
                approvalService: RemotePOSApprovalService(siteID: siteID)
            )
        } else if featureFlags.isFeatureFlagEnabled(.pointOfSaleLocalRoles) {
            return LocalPOSPermissionProvider(
                pinService: POSPINService(),
                appAccountUserID: userID,
                appAccountDisplayName: displayName
            )
        } else {
            return EmptyPOSPermissionProvider()
        }
    }
}
```

- [ ] **Step 2: Wire into POSTabCoordinator**

In `POSTabCoordinator.swift`, create the permission provider and pass it to `PointOfSaleEntryPointView`.

- [ ] **Step 3: Commit**

```bash
git add WooCommerce/Classes/POS/Adaptors/POSPermissionAdaptor.swift \
       WooCommerce/Classes/POS/TabBar/POSTabCoordinator.swift
git commit -m "Wire POS permission provider into app target via adaptor"
```

---

## Task 12: Networking layer for remote provider

**Files:**
- Create: `Modules/Sources/Networking/Remote/POSAuthRemote.swift`
- Create: `Modules/Sources/Yosemite/Actions/POSAuthAction.swift`
- Create: `Modules/Sources/Yosemite/Stores/POSAuthStore.swift`
- Create: `WooCommerce/Classes/POS/Adaptors/RemotePOSApprovalService.swift`

- [ ] **Step 1: Create POSAuthRemote in Networking**

Remote that calls the 4 POS auth endpoints using the existing Networking infrastructure (extends `Remote` base class, uses `AlamofireNetwork`).

- [ ] **Step 2: Create POSAuthAction in Yosemite**

Action enum with cases: `.authenticatePIN`, `.requestApproval`, `.managePIN`, `.fetchStaffStatus`

- [ ] **Step 3: Create POSAuthStore in Yosemite**

Store that handles the actions, calls the remote, and returns results.

- [ ] **Step 4: Create RemotePOSApprovalService**

Concrete implementation of `POSApprovalServiceProtocol` in the app target that dispatches Yosemite actions.

- [ ] **Step 5: Wire into RemotePOSPermissionProvider**

Update the `POSPermissionAdaptor` to pass the real networking closures to `RemotePOSPermissionProvider`.

- [ ] **Step 6: Commit**

```bash
git add Modules/Sources/Networking/Remote/POSAuthRemote.swift \
       Modules/Sources/Yosemite/Actions/POSAuthAction.swift \
       Modules/Sources/Yosemite/Stores/POSAuthStore.swift \
       WooCommerce/Classes/POS/Adaptors/RemotePOSApprovalService.swift \
       WooCommerce/Classes/POS/Adaptors/POSPermissionAdaptor.swift
git commit -m "Add networking layer for POS remote auth and approval"
```

---

## Task 13: Comprehensive tests

**Files:**
- Create/modify test files for all components

- [ ] **Step 1: Write integration tests for permission gating**

Test that when a cashier operator is signed in, restricted actions properly return `.requiresOverride`.

- [ ] **Step 2: Write tests for PIN service**

Test set, verify, delete, format validation for local PIN service.

- [ ] **Step 3: Write tests for feature flag switching**

Test that the correct provider is created based on feature flag state.

- [ ] **Step 4: Write tests for role eligibility changes**

Verify pos_cashier and pos_manager are ineligible for app login.

- [ ] **Step 5: Run full test suite**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests"
```

- [ ] **Step 6: Commit**

```bash
git add Modules/Tests/PointOfSaleTests/Roles/
git commit -m "Add comprehensive tests for POS roles and permissions"
```

---

## Task 14: Lint and final verification

- [ ] **Step 1: Run SwiftLint**

```bash
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory swiftlint --working-directory .. --quiet && popd
```

- [ ] **Step 2: Fix any lint issues**

- [ ] **Step 3: Run full build**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator build
```

- [ ] **Step 4: Run all POS tests**

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator \
  test -only-testing:"PointOfSaleTests"
```

- [ ] **Step 5: Commit any remaining fixes**

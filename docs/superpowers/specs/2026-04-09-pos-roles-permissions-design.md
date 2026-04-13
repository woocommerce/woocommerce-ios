# POS Roles & Permissions - iOS Design Spec

**Date:** 2026-04-09
**Backend:** `feature/pos-roles-permissions` on `Projects/woocommerce` (23 commits, 150+ tests, fully built)
**Decisions:** `POS Roles and Permissions - Decisions and FAQ.md`

---

## 1. Goal

Add role-based access control to WooCommerce POS on iOS. Two implementations behind a shared protocol, switchable via feature flags:

- **Remote** (preferred, flag: `posRemoteRoles`): PIN auth via REST API, Application Password sessions, capabilities from backend
- **Local** (fallback, flag: `posLocalRoles`): Manager PIN + Cashier PIN on device, hardcoded capability sets, no server dependency

Both share all UI: PIN entry, manager override, permission-gated views. Remote preferred when both flags active.

---

## 2. Roles & Login Model

### App login (unchanged)
- Only `administrator` and `shop_manager` can log into the WooCommerce app
- This is the **device credential** - unchanged from today

### POS operator roles (new, PIN-only)
- `pos_manager` - full POS access, can approve overrides. Cannot log into app.
- `pos_cashier` - limited POS access, restricted actions need manager override. Cannot log into app.

### Login gate
- `pos_cashier` and `pos_manager` added to `User.Role` enum but NOT to `eligibleRoles`
- Tailored error when they try to log in: "This account is set up for POS use only. Ask your store manager to sign you in on the POS device."
- Primary button: "Log In With Another Account"

### V1 role model (from decisions doc P3)
- Full app login: `administrator`, `shop_manager`
- Active POS operator after PIN: `pos_cashier`, `pos_manager`, `shop_manager`, `administrator`
- The app-authenticated user (admin/shop_manager) operates POS without PIN until they lock it

---

## 3. Permission Model

### 15 capabilities (matching backend)

```
woocommerce_pos_access
woocommerce_pos_manage_settings
woocommerce_void_orders
woocommerce_refund_orders
woocommerce_apply_discounts
woocommerce_override_prices
woocommerce_view_sales_reports
woocommerce_view_financial_reports
woocommerce_view_personal_sales
woocommerce_export_reports
woocommerce_approve_overrides
woocommerce_view_customer_data
woocommerce_edit_customer_data
woocommerce_view_audit_logs
woocommerce_adjust_stock
```

### Two permission states (not three)
- **Allowed**: action proceeds
- **Requires Override**: manager enters PIN, action proceeds after approval

No "denied/hidden" state. Everything a cashier can see, they can initiate. If they lack the capability, it triggers the manager override flow. This follows Shopify's "Approval Required" pattern.

### Defense in depth
```
1. Frontend: check capability map -> show action or show "Requires Approval"
2. If frontend misses: Backend rejects (403)
3. App catches 403 -> shows manager override prompt
4. Manager PIN -> POST /wc/v3/pos/auth/approve -> approval token
5. Retry with _pos_approval token -> succeeds
```

### Permission matrix (V1 POS features)

| Action | Cashier | Manager |
|--------|---------|---------|
| Process sales, payments | Allowed | Allowed |
| Apply existing coupons | Allowed | Allowed |
| View order history | Allowed | Allowed |
| Send receipts | Allowed | Allowed |
| Connect card reader | Allowed | Allowed |
| Process refund | Override | Allowed |
| Create new coupon | Override | Allowed |
| Void/cancel order | Override | Allowed |
| Access POS Settings | Override (session switch) | Allowed |
| Exit POS | Account holder PIN only | Account holder PIN only |

### Override types
- **Transactional** (refunds, coupons, void): Manager PIN in modal, action executes, cashier continues
- **Session switch** (settings): Manager PIN in modal, device switches to manager session, manager accesses settings, locks when done
- **App boundary** (exit POS): Only the app account holder's PIN works - not any manager, only the person who logged into the app with WP credentials

---

## 4. POS Containment

When POS is locked (any operator is PIN-authenticated):
- "Exit POS" requires the **app account holder's** PIN specifically
- Even a pos_manager cannot exit POS - they never authenticated with WP credentials
- Settings access via manager override switches the active session

### PIN screen elements (following Shopify/Square patterns)
- PIN numpad (4-6 digits, auto-submit)
- Staff name display (if known)
- PIN dots with shake on error
- Rate limiting: 5 failures = 30s lockout
- Bottom link: "Log in with a different account" - triggers full WP logout and re-authentication (following Shopify's pattern of having a logout option on the PIN screen)

---

## 5. Activation (from decisions doc P2)

No global toggle. PINs ARE the activation mechanism.
- Admin/Shop Manager opens POS without PIN (as today)
- They tap "Lock POS" -> app shows PIN screen
- If no PINs are set, "Lock POS" routes to PIN setup
- Once locked, re-entry requires a PIN

---

## 6. Local vs Remote Implementation

### Shared protocol

```swift
protocol POSPermissionProviding {
    var currentOperator: POSOperator? { get }
    func hasCapability(_ capability: String) -> Bool
    func checkPermission(_ capability: String) -> POSPermissionResult
    var isLocked: Bool { get }
}
```

### Remote implementation
- PIN auth: `POST /wc/v3/pos/auth/pin` with device credential
- Returns: user info, capabilities dict, Application Password, session metadata
- Capabilities cached locally for instant checks
- Override: `POST /wc/v3/pos/auth/approve` returns single-use order-scoped token
- Session: idle timeout 30min, TTL 12h, 401 triggers re-PIN
- Staff list: `GET /wc/v3/pos/auth/pin/status` (manage_woocommerce only)

### Local implementation
- Two PINs in POS Settings: Manager PIN, Cashier PIN
- Stored in iOS Keychain (hashed)
- Hardcoded capability sets matching backend roles:
  - Manager: all 15 capabilities
  - Cashier: `pos_access`, `view_personal_sales`, `view_customer_data`
- Override: local PIN verification, no token (API calls use app account credential)
- No staff list, no session timeouts

### Feature flag logic
```
posRemoteRoles ON  -> RemoteProvider
posLocalRoles ON   -> LocalProvider
neither            -> no roles, POS works as today
both               -> RemoteProvider (preferred)
```

---

## 7. Backend API (fully built)

| Endpoint | Method | Auth | Purpose |
|----------|--------|------|---------|
| `/wc/v3/pos/auth/pin` | POST | Device credential | Validate PIN, create session |
| `/wc/v3/pos/auth/pin/manage` | POST | Device or self | Set/delete PIN |
| `/wc/v3/pos/auth/pin/status` | GET | manage_woocommerce | List POS users + PIN status |
| `/wc/v3/pos/auth/approve` | POST | Operator credential | Manager approval token |

### PIN auth response
```json
{
  "user_id": 42,
  "display_name": "Jane Doe",
  "role": "pos_cashier",
  "capabilities": {"woocommerce_pos_access": true, ...},
  "application_password": "xxxx xxxx xxxx xxxx",
  "application_password_uuid": "uuid",
  "session_expires": "2026-04-10T01:30:00+00:00",
  "idle_timeout_seconds": 1800
}
```

### Approval response
```json
{
  "approved": true,
  "approver_id": 43,
  "approver_name": "Mike Smith",
  "approval_token": "32-char-string",
  "expires_in": 300
}
```

### Error codes
| Code | HTTP | App action |
|------|------|------------|
| `woocommerce_pos_session_expired` | 401 | Show PIN screen |
| `woocommerce_pos_invalid_pin` | 422 | Shake, show error |
| `woocommerce_pos_rate_limited` | 429 | Show lockout countdown |
| `woocommerce_rest_cannot_refund` | 403 | Trigger approval flow |
| `woocommerce_rest_cannot_cancel` | 403 | Trigger approval flow |
| `woocommerce_rest_cannot_apply_discounts` | 403 | Trigger approval flow |
| `woocommerce_rest_cannot_override_prices` | 403 | Trigger approval flow |

---

## 8. iOS Integration Points

### New files (PointOfSale module)
```
Roles/
  Models/
    POSOperator.swift
    POSPermissionResult.swift
  Providers/
    POSPermissionProviding.swift
    RemotePOSPermissionProvider.swift
    LocalPOSPermissionProvider.swift
  Services/
    POSPINService.swift
    POSSessionManager.swift
  Views/
    POSPINEntryView.swift
    POSManagerOverrideView.swift
    POSLockScreenView.swift
    POSStaffSettingsView.swift
```

### Modified files
- `User+Roles.swift` - add posCashier, posManager (not eligible)
- `RoleErrorViewModel.swift` - tailored POS error message
- `POSDependencyProviding.swift` - add permissions provider
- `POSEnvironmentKeys.swift` - add posPermissions key
- `PointOfSaleAggregateModel.swift` - integrate permission provider
- `PointOfSaleEntryPointView.swift` - wrap with lock screen
- `POSFloatingControlView.swift` - gate Exit POS, add Lock POS
- `POSSettingsView.swift` - add Staff section
- Refund views - gate with permission check / override
- Coupon creation views - gate with permission check / override
- `Experiments/FeatureFlag.swift` - add posRemoteRoles, posLocalRoles

---

## 9. What NOT to Build
- Custom roles, permission toggles, three-tier config
- Cash management (drawer, reconciliation)
- Clock in/out, time tracking
- Multi-location scoping
- PIN expiration/rotation
- Threshold permissions
- Remote approval via push notification
- iOS Guided Access integration (recommend only)
- Custom audit log UI

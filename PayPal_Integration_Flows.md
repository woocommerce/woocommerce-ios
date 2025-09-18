# PayPal Card Reader Integration Flows

## Overview

This document outlines the different authentication and payment flows available in the WooCommerce iOS app for PayPal card readers.

## Authentication Methods

### 1. Site-Managed OAuth (Recommended)
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Mobile App    │    │  WooCommerce     │    │   Zettle API    │
│                 │    │  Site + Plugin   │    │                 │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                       │                       │
         │ 1. Request Token      │                       │
         ├──────────────────────>│                       │
         │                       │ 2. Get OAuth Token   │
         │                       ├──────────────────────>│
         │                       │ 3. Return Token      │
         │                       │<──────────────────────┤
         │ 4. Return Token       │                       │
         │<──────────────────────┤                       │
         │                       │                       │
         │ 5. Use Token for Reader Operations              │
         ├─────────────────────────────────────────────>│
```

**Benefits:**
- No sensitive credentials in mobile app
- Centralized OAuth management
- Better security
- Works across multiple apps/devices

### 2. Basic OAuth (Simple)
```
┌─────────────────┐    ┌─────────────────┐
│   Mobile App    │    │   Zettle API    │
│                 │    │                 │
└─────────────────┘    └─────────────────┘
         │                       │
         │ 1. Direct Login       │
         ├──────────────────────>│
         │ 2. OAuth Token        │
         │<──────────────────────┤
         │                       │
         │ 3. Use Token for Operations
         ├──────────────────────>│
```

**Benefits:**
- Simpler setup
- No plugin required
- Direct PayPal login

## Onboarding Flow Comparison

### Current (Stripe/WooPayments)
```
App Launch → Check Plugins → Select Plugin → Configure → Connect Reader
```

### With PayPal Integration
```
App Launch → Check Plugins → Select Plugin (Stripe/WooPayments/PayPal) → Configure → Connect Reader
```

## Reader Connection Flow

### Stripe/WooPayments
```
1. Discovery → 2. Bluetooth Scan → 3. Select Reader → 4. Pair → 5. Connected
```

### PayPal/Zettle
```
1. Discovery → 2. Authenticate (Login/Token) → 3. Connected*
```
*PayPal readers auto-discover during payment - no separate pairing step

## Payment Flow Comparison

### Stripe/WooPayments
```
┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│ Create       │    │ Authorize    │    │ Capture      │
│ PaymentIntent│───>│ on Reader    │───>│ on Server    │
└──────────────┘    └──────────────┘    └──────────────┘
     App                Reader              Server
```

### PayPal/Zettle
```
┌──────────────┐    ┌──────────────┐
│ Create       │    │ Charge &     │
│ Payment      │───>│ Capture      │
└──────────────┘    └──────────────┘
     App             PayPal SDK
                   (handles reader)
```

## Key Differences

| Aspect | Stripe/WooPayments | PayPal/Zettle |
|--------|-------------------|---------------|
| **Reader Discovery** | Bluetooth scan | Auto-discovery |
| **Reader Connection** | Manual pairing | Auth-based |
| **Payment UI** | Custom WooCommerce UI | PayPal SDK UI |
| **Payment Flow** | Authorize → Capture | Direct capture |
| **Plugin Dependency** | Required | Optional (for site-managed auth) |
| **Hardware Cost** | ~$299+ | ~$169+ |
| **Geographic Availability** | Limited | Wider (EU focus) |

## Settings Integration

### Debug Settings (Current)
- Toggle: "Use PayPal (Debug)"
- PayPal Settings button (when enabled)

### Enhanced Settings (New)
- Toggle: "Use PayPal (Debug)"
- Toggle: "Site-Managed Auth" (when PayPal enabled)
- PayPal Settings button (when enabled)

## Technical Implementation Notes

### iOS App Changes
1. `ServiceLocator` - Switch between CardReaderService implementations
2. `PayPalCardReaderService` - Dual auth mode support
3. Settings UI - Auth method toggle
4. Config providers - Token fetching from site

### Backend Plugin Changes
1. Admin interface for Zettle OAuth setup
2. REST endpoints for token provisioning
3. Encrypted token storage
4. PKCE OAuth flow implementation

## Demo Scenarios

### Scenario 1: Site-Managed Auth
1. Admin configures Zettle client ID in WordPress
2. Admin authorizes with Zettle (one-time setup)
3. Mobile app uses site tokens automatically
4. Payment works seamlessly

### Scenario 2: Basic Auth
1. No plugin configuration needed
2. Mobile app shows PayPal login during first use
3. Subsequent payments use stored credentials
4. Simple but less secure

## Next Steps for Production

1. **Security audit** of OAuth implementation
2. **Real Zettle client IDs** for testing
3. **Error handling** improvements
4. **Plugin store integration** for full onboarding
5. **Multi-store support** consideration
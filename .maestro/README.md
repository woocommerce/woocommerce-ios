# WooCommerce iOS - Maestro Smoke Tests

Automated UI smoke tests for WooCommerce iOS using [Maestro](https://maestro.mobile.dev/).

## Prerequisites

- macOS with Xcode and Command Line Tools installed
- Java 17+ (`brew install openjdk` if missing)
- iOS Simulator booted
- Maestro CLI installed

## Installation

```bash
# Install Maestro
curl -fsSL "https://get.maestro.mobile.dev" | bash

# Verify installation
maestro --version
```

## Setup

1. Set environment variables with your test store credentials:

```bash
export MAESTRO_WOO_EMAIL="your-email@example.com"
export MAESTRO_WOO_PASSWORD="your-password"
export MAESTRO_WOO_STORE_URL="https://your-store.wpcomstaging.com"
```

2. Build and install the app on the simulator:

```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' -sdk iphonesimulator build
```

3. Boot a simulator if not already running:

```bash
xcrun simctl boot "iPhone 16"
```

## Running Tests

```bash
# Run all smoke tests
rake maestro

# Or directly with maestro CLI
maestro test --include-tags=smoke .maestro/

# Run a specific category
maestro test --include-tags=login .maestro/
maestro test --include-tags=orders .maestro/
maestro test --include-tags=products .maestro/
maestro test --include-tags=dashboard .maestro/
maestro test --include-tags=menu .maestro/

# Run a single flow
maestro test .maestro/flows/login_successful.yaml

# Pass credentials inline (without MAESTRO_ prefix)
maestro test -e WOO_EMAIL="..." -e WOO_PASSWORD="..." -e WOO_STORE_URL="..." .maestro/
```

## Directory Structure

```
.maestro/
├── config.yaml          # Workspace configuration (appId, flow order)
├── env.example          # Environment variables template
├── .gitignore           # Ignores reports and screenshots
├── README.md            # This file
├── flows/               # Test flows (one per feature scenario)
│   ├── login_successful.yaml
│   ├── login_not_wp_site.yaml
│   ├── login_wrong_credentials.yaml
│   ├── dashboard_stats.yaml
│   ├── orders_list_and_search.yaml
│   ├── orders_create.yaml
│   ├── orders_details_and_actions.yaml
│   ├── products_list_and_sort.yaml
│   ├── products_detail.yaml
│   ├── products_create.yaml
│   ├── menu_settings.yaml
│   ├── menu_payments.yaml
│   ├── menu_reviews.yaml
│   ├── menu_view_store.yaml
│   ├── blaze_campaign.yaml
│   └── google_for_woo.yaml
├── subflows/            # Reusable subflows
│   ├── login.yaml
│   ├── navigate_to_dashboard.yaml
│   ├── navigate_to_orders.yaml
│   ├── navigate_to_products.yaml
│   └── navigate_to_menu.yaml
└── scripts/             # JavaScript validation helpers
    ├── validate_order_number.js
    └── validate_product_count.js
```

## Test Coverage

| Area | Flow | Tags |
|------|------|------|
| Login | Successful WPCom login | `smoke`, `login` |
| Login | Not a WordPress site error | `smoke`, `login` |
| Login | Wrong credentials error | `smoke`, `login` |
| Dashboard | Stats and analytics | `smoke`, `dashboard` |
| Orders | List, pagination, and search | `smoke`, `orders` |
| Orders | Create a new order | `smoke`, `orders` |
| Orders | Detail view and actions | `smoke`, `orders` |
| Products | List, sort, and search | `smoke`, `products` |
| Products | Product detail view | `smoke`, `products` |
| Products | Create a new product | `smoke`, `products` |
| Menu | Settings | `smoke`, `settings`, `menu` |
| Menu | Payments | `smoke`, `payments`, `menu` |
| Menu | Reviews | `smoke`, `reviews`, `menu` |
| Menu | View Store | `smoke`, `menu` |
| Blaze | Campaign creation | `smoke`, `blaze`, `menu` |
| Google Ads | Campaign webview | `smoke`, `google_for_woo`, `menu` |

## Credentials

Environment variables follow the `MAESTRO_` prefix convention (shared with Android):

| Variable | Required | Description |
|----------|----------|-------------|
| `MAESTRO_WOO_EMAIL` | Yes | WordPress.com email for test store |
| `MAESTRO_WOO_PASSWORD` | Yes | WordPress.com password |
| `MAESTRO_WOO_STORE_URL` | Yes | WooCommerce store URL |
| `MAESTRO_WOO_CUSTOMER_NAME` | No | Customer name for order creation |

Variables prefixed with `MAESTRO_` are automatically available in flows as `${VAR_NAME}` (without the prefix). E.g., `MAESTRO_WOO_EMAIL` becomes `${WOO_EMAIL}`.

## Adding New Flows

1. Create a new YAML file in `flows/`
2. Set the `appId`, `name`, and `tags` in the frontmatter
3. Start with `runFlow: ../subflows/login.yaml` to handle authentication
4. Use `runFlow: ../subflows/navigate_to_<tab>.yaml` for navigation
5. Use iOS accessibility identifiers for element selection (check `Modules/Sources/UITestsFoundation/Screens/` for reference)
6. Add screenshots at key checkpoints with `takeScreenshot: name`
7. Add the flow to `config.yaml`'s `flowsOrder` list

## Cross-Platform Alignment

These tests mirror the Android Maestro smoke tests in structure and naming. While the YAML flows cannot be shared directly (different accessibility IDs and UI patterns), the following are aligned:

- Directory structure (`.maestro/flows/`, `.maestro/subflows/`, `.maestro/scripts/`)
- Environment variable naming (`MAESTRO_WOO_*`)
- Flow naming convention (e.g., `login_successful.yaml`, `orders_create.yaml`)
- Tag strategy (`smoke`, feature-specific tags)
- Test coverage scope (same user journeys)

## Troubleshooting

- **Maestro not found**: Ensure `~/.maestro/bin` is in your PATH
- **No simulator**: Run `xcrun simctl boot "iPhone 16"` or check available devices with `xcrun simctl list devices available`
- **App not installed**: Build the app first with `xcodebuild`
- **Login fails**: Verify credentials are correct and the store URL is accessible
- **Element not found**: iOS accessibility identifiers may change between releases; check `Modules/Sources/UITestsFoundation/Screens/` for current IDs

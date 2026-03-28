# AI-Powered Troubleshooting Chat

An interactive, chat-based troubleshooting interface in **Settings > Help** that guides users through diagnosing common issues. The feature runs automated checks, offers one-tap fixes, and uses Jetpack AI to analyze free-form problem descriptions — with Zendesk support as a last resort.

**Feature flag**: `.aiHelp` (enabled for `localDeveloper` and `alpha` builds)

---

## How It Works

1. User opens **Settings > Help & Support > Troubleshoot with AI**
2. A header displays the current site name, URL, and authentication status
3. User selects a topic from the list below
4. The system runs relevant diagnostics and presents results inline as a chat conversation
5. Actionable fixes are offered as buttons (e.g., "Enable Analytics", "Enable Order Notifications")
6. If the issue isn't resolved, the user can file a Zendesk support ticket

---

## Topic Options

### Analytics
- Checks whether WooCommerce Analytics is enabled via `SettingAction.retrieveAnalyticsSetting`
- **If disabled**: offers an "Enable Analytics" button that calls `SettingAction.enableAnalyticsSetting`, then asks the user to relaunch the app
- **If enabled**: confirms the setting is active and offers to contact support if the issue persists
- **If check fails**: shows the error and offers Zendesk escalation

### Loading Orders
- Attempts to fetch a single order via `OrderAction.fetchFilteredOrders` (page 1, size 1, no storage write)
- **Success**: confirms order loading works, suggests pull-to-refresh
- **Failure**: reports the error, suggests checking internet connectivity, offers support escalation

### Loading Products
- Attempts to sync a single product via `ProductAction.synchronizeProducts` (page 1, size 1)
- **Success**: confirms product loading works, suggests pull-to-refresh
- **Failure**: reports the error, suggests checking connectivity, offers support escalation

### Order Notifications
Runs a multi-step diagnostic sequence:

1. **WordPress.com authentication** — verifies the user is signed in with a WPCom account (required for push notifications)
2. **Jetpack status** — checks that Jetpack is installed and connected on the site
3. **iOS notification permissions** — queries `UNUserNotificationCenter` for authorization status; offers an "Open Settings" button if denied
4. **Site notification settings** — loads per-device settings via `AccountAction.loadNotificationSettings` and reports the state of order and review notifications individually:
   - If order notifications are disabled: offers "Enable Order Notifications" button
   - If review notifications are disabled: offers "Enable Review Notifications" button
   - Enabling is done via `AccountAction.updateNotificationSettings`

### Order Details / Shipping
- Asks the user to describe their issue in free text
- Sends the description to Jetpack AI for analysis
- AI returns 2–3 actionable troubleshooting steps
- Offers Zendesk escalation if the steps don't help

### Card Reader / In-Person Payments
- Same free-text + AI analysis flow as above

### Load / Upload Product Images
- Same free-text + AI analysis flow as above

### Others
- Catch-all for issues not covered by the specific categories
- Same free-text + AI analysis flow

---

## Future Improvements

### Chat transcript as Zendesk attachment
Attach the full in-app chat transcript (diagnostic results, user inputs, AI suggestions) to the Zendesk ticket so support agents have complete context without asking the user to repeat information.

### Persistent conversation history
Allow users to revisit previous troubleshooting sessions. Store chat messages locally so they can reference past diagnostics or resume where they left off.

### Proactive issue detection
Instead of waiting for users to report problems, detect common issues in the background (e.g., failed syncs, expired credentials, disabled plugins) and surface a notification or badge on the Help screen suggesting a diagnostic run.

### Deeper AI integration
- **Contextual prompts**: Include WooCommerce version, active plugins, PHP version, and recent error logs in the AI prompt for more targeted suggestions. This data is available via `SystemStatusAction.fetchSystemStatusReport`.
- **Multi-turn conversation**: Allow follow-up questions where the AI remembers previous context within the same session, enabling a more natural back-and-forth troubleshooting flow.
- **Automatic action execution**: For certain AI suggestions (e.g., "clear the app cache", "force-sync orders"), offer one-tap buttons that execute the suggested action directly instead of just describing it.
- **Issue classification and routing**: Use AI to classify the severity and category of the issue, then route to the appropriate Zendesk queue or suggest relevant Help Center articles before opening a ticket.
- **Localized AI responses**: Detect the user's language from their input via `GenerativeContentAction.identifyLanguage` and instruct the AI to respond in the same language for a fully localized experience.
- **Learning from resolutions**: Track which diagnostic paths and AI suggestions successfully resolve issues (via analytics events) to improve prompt engineering and prioritize the most effective troubleshooting steps over time.

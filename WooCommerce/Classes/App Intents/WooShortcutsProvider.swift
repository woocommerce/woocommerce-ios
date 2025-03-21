import AppIntents
import StoreWidgetsExtension

struct WooShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [AppShortcut(intent: GoToPOSAppIntent(),
                    phrases: ["\(.applicationName) POS",
                              "Go to \(.applicationName) POS",
                              "Start \(.applicationName) POS"],
                    shortTitle: "Go To POS",
                    systemImageName: "cart.fill"),
         AppShortcut(intent: GetTodayRevenueAppIntent(),
                            phrases: ["Get today's revenue in \(.applicationName)",
                                      "See today's revenue in \(.applicationName)",
                                      "Show me how revenue I've had today in \(.applicationName)"],
                            shortTitle: "Get Today's Revenue",
                            systemImageName: "dollarsign")]
    }
}

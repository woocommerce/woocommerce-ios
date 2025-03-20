import AppIntents

struct WooShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: GoToPOSAppIntent(),
                    phrases: ["\(.applicationName) POS",
                              "Go to \(.applicationName) POS",
                              "Start \(.applicationName) POS"],
                    shortTitle: "Go To POS",
                    systemImageName: "cart.fill")
    }
}

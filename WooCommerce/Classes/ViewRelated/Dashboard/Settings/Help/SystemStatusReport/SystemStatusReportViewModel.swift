import Foundation
import Yosemite

/// View model for `SystemStatusReportView`
///
final class SystemStatusReportViewModel: ObservableObject {
    /// ID of the site to fetch system status report for
    ///
    private let siteID: Int64

    /// Stores to handle fetching system status
    ///
    private let stores: StoresManager

    /// Formatted system status report to be displayed on-screen
    ///
    @Published private(set) var statusReport: String = ""

    /// Whether fetching system status report failed
    ///
    @Published private(set) var errorFetchingReport: Bool = false

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func fetchReport() {
        errorFetchingReport = false
        let action = SystemStatusAction.fetchSystemStatusReport(siteID: siteID) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let status):
                self.statusReport = self.formatReport(with: status)
            case .failure:
                self.errorFetchingReport = true
            }
        }
        stores.dispatch(action)
    }
}

private extension SystemStatusReportViewModel {
    /// Format system status to match with Core's report.
    /// Not localizing content and keep English by default.
    ///
    func formatReport(with systemStatus: SystemStatus) -> String {
        var lines = ["### System Status Report generated via the WooCommerce iOS app ###"]

        // Environment
        if let environment = systemStatus.environment {
            lines.append(contentsOf: [
                "\n### WordPress Environment ###\n",
                "WordPress addresss (URL): \(environment.homeURL)",
                "Site address (URL): \(environment.siteURL)",
                "WC Version: \(environment.version)",
                "Log Directory Writable: \(environment.logDirectoryWritable.stringRepresentable)",
                "WP Version: \(environment.wpVersion)",
                "WP Multisite: \(environment.wpMultisite.stringRepresentable)",
                "WP Memory Limit: \(environment.wpMemoryLimit.byteCountRepresentable)",
                "WP Debug Mode: \(environment.wpDebugMode.stringRepresentable)",
                "WP Cron: \(environment.wpCron.stringRepresentable)",
                "Language: \(environment.language)",
                "External object cache: \((environment.externalObjectCache ?? false).stringRepresentable)",
                "\n### Server Environment ###\n",
                "Server Info: \(environment.serverInfo)",
                "PHP Version: \(environment.phpVersion)",
                "PHP Post Max Size: \(environment.phpPostMaxSize.byteCountRepresentable)",
                "PHP Time Limit: \(environment.phpMaxExecutionTime)",
                "PHP Max Input Vars: \(environment.phpMaxInputVars)",
                "cURL Version: \(environment.curlVersion)\n",
                "SUHOSIN Installed: \(environment.suhosinInstalled.stringRepresentable)",
                "MySQL Version: \(environment.mysqlVersion)",
                "Max Upload Size: \(environment.maxUploadSize.byteCountRepresentable)",
                "Default Timezone is UTC: \((environment.defaultTimezone == "UTC").stringRepresentable)",
                "fsockopen/cURL: \(environment.fsockopenOrCurlEnabled.stringRepresentable)",
                "SoapClient: \(environment.soapClientEnabled.stringRepresentable)",
                "DOMDocument: \(environment.domDocumentEnabled.stringRepresentable)",
                "GZip: \(environment.gzipEnabled.stringRepresentable)",
                "Multibyte String: \(environment.mbstringEnabled.stringRepresentable)",
                "Remote Post: \(environment.remotePostSuccessful.stringRepresentable)",
                "Remote Get: \(environment.remoteGetSuccessful.stringRepresentable)"
            ])
        }

        // Database
        if let database = systemStatus.database {
            lines.append(contentsOf: [
                "\n### Database ###\n",
                "WC Database Version: \(database.wcDatabaseVersion)",
                String(format: "Total Database Size: %.2fMB", database.databaseSize.data + database.databaseSize.index),
                String(format: "Database Data Size: %.2fMB", database.databaseSize.data),
                String(format: "Database Index Size: %.2fMB", database.databaseSize.index)
            ])

            for (tableName, content) in database.databaseTables.woocommerce {
                lines.append("\(tableName): Data: \(content.data)MB + Index: \(content.index)MB + Engine \(content.engine)")
            }

            for (tableName, content) in database.databaseTables.other {
                lines.append("\(tableName): Data: \(content.data)MB + Index: \(content.index)MB + Engine \(content.engine)")
            }
        }

        // Post Type Counts
        if systemStatus.postTypeCounts.isNotEmpty {
            lines.append("\n### Post Type Counts ###\n")
            for postTypeCount in systemStatus.postTypeCounts {
                lines.append("\(postTypeCount.type): \(postTypeCount.count)")
            }
        }

        // Security
        if let security = systemStatus.security {
            lines.append(contentsOf: [
                "\n### Security ###\n",
                "Secure connection (HTTPS): \(security.secureConnection.stringRepresentable)",
                "Hide errors from visitors: \(security.hideErrors.stringRepresentable)"
            ])
        }

        // Active plugins
        if systemStatus.activePlugins.isNotEmpty {
            lines.append("\n### Active Plugins (\(systemStatus.activePlugins.count)) ###\n")
            for plugin in systemStatus.activePlugins {
                lines.append("\(plugin.name): by \(plugin.authorName) - \(plugin.version)")
            }
        }

        // Inactive plugins
        if systemStatus.inactivePlugins.isNotEmpty {
            lines.append("\n### Inactive Plugins (\(systemStatus.inactivePlugins.count)) ###\n")
            for plugin in systemStatus.inactivePlugins {
                lines.append("\(plugin.name): by \(plugin.authorName) - \(plugin.version)")
            }
        }

        // Dropin plugins
        if systemStatus.dropinPlugins.isNotEmpty {
            lines.append("\n### Dropin Plugins (\(systemStatus.dropinPlugins.count)) ###\n")
            for plugin in systemStatus.dropinPlugins {
                lines.append("\(plugin.plugin): \(plugin.name)")
            }
        }

        // Must Use plugins
        if systemStatus.mustUsePlugins.isNotEmpty {
            lines.append("\n### Must Use Plugins (\(systemStatus.mustUsePlugins.count)) ###\n")
            for plugin in systemStatus.mustUsePlugins {
                lines.append("\(plugin.plugin): \(plugin.name)")
            }
        }

        // Settings
        if let settings = systemStatus.settings {
            lines.append(contentsOf: [
                "\n### Settings ###\n",
                "API Enabled: \(settings.apiEnabled.stringRepresentable)",
                "Force SSL: \(settings.forceSSL.stringRepresentable)",
                "Currency: \(settings.currency)",
                "Currency Position: \(settings.currencyPosition)",
                "Thousand Separator: \(settings.thousandSeparator)",
                "Decimal Separator: \(settings.decimalSeparator)",
                "Number of Decimals: \(settings.numberOfDecimals)"
            ])

            for (index, content) in settings.taxonomies.enumerated() {
                if index == 0 {
                    lines.append("\nTaxonomies: Product Types: \(content.key) (\(content.value))")
                } else {
                    lines.append("\(content.key) (\(content.value))")
                }
            }
            for (index, content) in settings.productVisibilityTerms.enumerated() {
                if index == 0 {
                    lines.append("\nTaxonomies: Product Visibility: \(content.key) (\(content.value))")
                } else {
                    lines.append("\(content.key) (\(content.value))")
                }
            }
            lines.append("\nConnected to WooCommerce.com: \((settings.woocommerceCOMConnected != "no").stringRepresentable)")
        }

        // Pages
        if systemStatus.pages.isNotEmpty {
            lines.append("\n### WC Pages ###\n")
            for page in systemStatus.pages {
                let pageID = page.pageSet ? "#\(page.pageID)" : "❌ Page not set"
                lines.append("\(page.pageName): \(pageID)")
            }
        }

        // Theme
        if let theme = systemStatus.theme {
            lines.append(contentsOf: [
                "\n### Theme ###\n",
                "Name: \(theme.name)",
                "Version: \(theme.version)",
                "Author URL: \(theme.authorURL)",
                "Child Theme: \(theme.isChildTheme ? "✔" : "❌") – " +
                "If you are modifying WooCommerce on a parent theme that you did not build personally " +
                "we recommend using a child theme. See: How to create a child theme",
                "WooCommerce Support: \(theme.hasWoocommerceSupport.stringRepresentable)",
                "WooCommerce files: \(theme.hasWoocommerceSupport.stringRepresentable)",
                "Outdated templates: \(theme.hasOutdatedTemplates.stringRepresentable)",
                "\n### Templates ###\n",
            ])
            if theme.overrides.isEmpty {
                lines.append("Overrides: -")
            } else {
                for (index, item) in theme.overrides.enumerated() {
                    lines.append("\(index == 0 ? "Overrides: " : "")\(item["file"] ?? "")")
                }
            }
        }

        let dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat

        lines.append(contentsOf: [
            "\n### Status report information ###\n",
            "Generated at: \(dateFormatter.string(from: Date()))"
        ])
        return lines.joined(separator: "\n")
    }
}

private extension Bool {
    /// Represents bool value with a string
    ///
    var stringRepresentable: String {
        self ? "✔" : "–"
    }
}

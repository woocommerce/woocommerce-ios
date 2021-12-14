import Foundation

public extension SystemStatus {
    /// Subtype for details about environment in system status.
    ///
    struct Environment: Decodable {
        let homeURL: String
        let siteURL: String
        let version: String
        let logDirectoryWritable: Bool
        let wpVersion: String
        let wpMultisite: Bool
        let wpMemoryLimit: Int64
        let wpDebugMode: Bool
        let wpCron: Bool
        let language: String
        let externalObjectCache: Bool
        let serverInfo: String
        let phpVersion: String
        let phpPostMaxSize: Int64
        let phpMaxExecutionTime: Int64
        let phpMaxInputVars: Int64
        let curlVersion: String
        let suhosinInstalled: Bool
        let maxUploadSize: Int64
        let mysqlVersion: String
        let defaultTimezone: String
        let fsockopenOrCurlEnabled: Bool
        let soapClientEnabled: Bool
        let domDocumentEnabled: Bool
        let gzipEnabled: Bool
        let mbstringEnabled: Bool
        let remotePostSuccessful: Bool
        let remoteGetSuccessful: Bool

        public init(
            homeURL: String,
            siteURL: String,
            version: String,
            logDirectoryWritable: Bool,
            wpVersion: String,
            wpMultisite: Bool,
            wpMemoryLimit: Int64,
            wpDebugMode: Bool,
            wpCron: Bool,
            language: String,
            externalObjectCache: Bool,
            serverInfo: String,
            phpVersion: String,
            phpPostMaxSize: Int64,
            phpMaxExecutionTime: Int64,
            phpMaxInputVars: Int64,
            curlVersion: String,
            suhosinInstalled: Bool,
            maxUploadSize: Int64,
            mysqlVersion: String,
            defaultTimezone: String,
            fsockopenOrCurlEnabled: Bool,
            soapClientEnabled: Bool,
            domDocumentEnabled: Bool,
            gzipEnabled: Bool,
            mbstringEnabled: Bool,
            remotePostSuccessful: Bool,
            remoteGetSuccessful: Bool
        ) {
            self.homeURL = homeURL
            self.siteURL = siteURL
            self.version = version
            self.logDirectoryWritable = logDirectoryWritable
            self.wpVersion = wpVersion
            self.wpMultisite = wpMultisite
            self.wpMemoryLimit = wpMemoryLimit
            self.wpDebugMode = wpDebugMode
            self.wpCron = wpCron
            self.language = language
            self.externalObjectCache = externalObjectCache
            self.serverInfo = serverInfo
            self.phpVersion = phpVersion
            self.phpPostMaxSize = phpPostMaxSize
            self.phpMaxExecutionTime = phpMaxExecutionTime
            self.phpMaxInputVars = phpMaxInputVars
            self.curlVersion = curlVersion
            self.suhosinInstalled = suhosinInstalled
            self.maxUploadSize = maxUploadSize
            self.mysqlVersion = mysqlVersion
            self.defaultTimezone = defaultTimezone
            self.fsockopenOrCurlEnabled = fsockopenOrCurlEnabled
            self.soapClientEnabled = soapClientEnabled
            self.domDocumentEnabled = domDocumentEnabled
            self.gzipEnabled = gzipEnabled
            self.mbstringEnabled = mbstringEnabled
            self.remotePostSuccessful = remotePostSuccessful
            self.remoteGetSuccessful = remoteGetSuccessful
        }

        /// The public initializer for Environment.
        ///
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let homeURL = try container.decode(String.self, forKey: .homeURL)
            let siteURL = try container.decode(String.self, forKey: .siteURL)
            let version = try container.decode(String.self, forKey: .version)
            let logDirectoryWritable = try container.decode(Bool.self, forKey: .logDirectoryWritable)
            let wpVersion = try container.decode(String.self, forKey: .wpVersion)
            let wpMultisite = try container.decode(Bool.self, forKey: .wpMultisite)
            let wpMemoryLimit = try container.decode(Int64.self, forKey: .wpMemoryLimit)
            let wpDebugMode = try container.decode(Bool.self, forKey: .wpDebugMode)
            let wpCron = try container.decode(Bool.self, forKey: .wpCron)
            let language = try container.decode(String.self, forKey: .language)
            let externalObjectCache = (try? container.decode(Bool.self, forKey: .externalObjectCache)) ?? false
            let serverInfo = try container.decode(String.self, forKey: .serverInfo)
            let phpVersion = try container.decode(String.self, forKey: .phpVersion)
            let phpPostMaxSize = try container.decode(Int64.self, forKey: .phpPostMaxSize)
            let phpMaxExecutionTime = try container.decode(Int64.self, forKey: .phpMaxExecutionTime)
            let phpMaxInputVars = try container.decode(Int64.self, forKey: .phpMaxInputVars)
            let curlVersion = try container.decode(String.self, forKey: .curlVersion)
            let suhosinInstalled = try container.decode(Bool.self, forKey: .suhosinInstalled)
            let maxUploadSize = try container.decode(Int64.self, forKey: .maxUploadSize)
            let mysqlVersion = try container.decode(String.self, forKey: .mysqlVersion)
            let defaultTimezone = try container.decode(String.self, forKey: .defaultTimezone)
            let fsockopenOrCurlEnabled = try container.decode(Bool.self, forKey: .fsockopenOrCurlEnabled)
            let soapClientEnabled = try container.decode(Bool.self, forKey: .soapClientEnabled)
            let domDocumentEnabled = try container.decode(Bool.self, forKey: .domDocumentEnabled)
            let gzipEnabled = try container.decode(Bool.self, forKey: .gzipEnabled)
            let mbstringEnabled = try container.decode(Bool.self, forKey: .mbstringEnabled)
            let remotePostSuccessful = try container.decode(Bool.self, forKey: .remotePostSuccessful)
            let remoteGetSuccessful = try container.decode(Bool.self, forKey: .remoteGetSuccessful)

            self.init(
                homeURL: homeURL,
                siteURL: siteURL,
                version: version,
                logDirectoryWritable: logDirectoryWritable,
                wpVersion: wpVersion,
                wpMultisite: wpMultisite,
                wpMemoryLimit: wpMemoryLimit,
                wpDebugMode: wpDebugMode,
                wpCron: wpCron,
                language: language,
                externalObjectCache: externalObjectCache,
                serverInfo: serverInfo,
                phpVersion: phpVersion,
                phpPostMaxSize: phpPostMaxSize,
                phpMaxExecutionTime: phpMaxExecutionTime,
                phpMaxInputVars: phpMaxInputVars,
                curlVersion: curlVersion,
                suhosinInstalled: suhosinInstalled,
                maxUploadSize: maxUploadSize,
                mysqlVersion: mysqlVersion,
                defaultTimezone: defaultTimezone,
                fsockopenOrCurlEnabled: fsockopenOrCurlEnabled,
                soapClientEnabled: soapClientEnabled,
                domDocumentEnabled: domDocumentEnabled,
                gzipEnabled: gzipEnabled,
                mbstringEnabled: mbstringEnabled,
                remotePostSuccessful: remotePostSuccessful,
                remoteGetSuccessful: remoteGetSuccessful
            )
        }
    }
}

private extension SystemStatus.Environment {
    enum CodingKeys: String, CodingKey {
        case homeURL = "home_url"
        case siteURL = "site_url"
        case version
        case logDirectoryWritable = "log_directory_writable"
        case wpVersion = "wp_version"
        case wpMultisite = "wp_multisite"
        case wpMemoryLimit = "wp_memory_limit"
        case wpDebugMode = "wp_debug_mode"
        case wpCron = "wp_cron"
        case language
        case externalObjectCache = "external_object_cache"
        case serverInfo = "server_info"
        case phpVersion = "php_version"
        case phpPostMaxSize = "php_post_max_size"
        case phpMaxExecutionTime = "php_max_execution_time"
        case phpMaxInputVars = "php_max_input_vars"
        case curlVersion = "curl_version"
        case suhosinInstalled = "suhosin_installed"
        case maxUploadSize = "max_upload_size"
        case mysqlVersion = "mysql_version_string"
        case defaultTimezone = "default_timezone"
        case fsockopenOrCurlEnabled = "fsockopen_or_curl_enabled"
        case soapClientEnabled = "soapclient_enabled"
        case domDocumentEnabled = "domdocument_enabled"
        case gzipEnabled = "gzip_enabled"
        case mbstringEnabled = "mbstring_enabled"
        case remotePostSuccessful = "remote_post_successful"
        case remoteGetSuccessful = "remote_get_successful"
    }
}

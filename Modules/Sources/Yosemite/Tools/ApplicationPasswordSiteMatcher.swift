import Foundation

/// Checks whether an application password approval page belongs to the store being logged into.
public enum ApplicationPasswordSiteMatcher {
    private static let wwwPrefix = "www."
    private static let approvalPage = "authorize-application.php"

    /// True when `candidateURL` is on `siteURL`'s host, ignoring `www.`, case, scheme and port, and at or below its path,
    /// so a subfolder install still matches while a sibling site on the same host doesn't.
    public static func isWithinSite(siteURL: String?, candidateURL: String?) -> Bool {
        guard let site = siteURL.flatMap(siteComponents), let candidate = candidateURL.flatMap(siteComponents) else {
            return false
        }
        let sitePath = serverPath(of: site).map { $0.lowercased() }
        let candidatePath = serverPath(of: candidate).map { $0.lowercased() }
        return comparableHost(of: site) == comparableHost(of: candidate) && candidatePath.starts(with: sitePath)
    }

    public static func isSameSiteAddress(_ siteURL: String?, _ candidateURL: String?) -> Bool {
        isWithinSite(siteURL: siteURL, candidateURL: candidateURL) && isWithinSite(siteURL: candidateURL, candidateURL: siteURL)
    }

    /// Also true with extra path after the page, and checked before `..` is resolved, because some servers run the page
    /// and pass the rest as extra path. Also true when the URL has a user name, so it then fails `isWithinSite`.
    public static func isApprovalPage(_ url: String?) -> Bool {
        guard let components = url.flatMap(componentsWithDefaultScheme) else {
            return false
        }
        return serverPath(of: components, resolveDots: false).contains(where: isApprovalPageSegment)
    }

    /// The WordPress address that serves the approval page: the URL before the admin directory and the page,
    /// with no trailing slash. Nil when the URL isn't an approval page.
    public static func approvalSiteURL(for authorizationURL: String?) -> String? {
        guard let url = authorizationURL.flatMap(siteComponents) else {
            return nil
        }
        let segments = serverPath(of: url)
        guard let approvalPageIndex = segments.lastIndex(where: isApprovalPageSegment), approvalPageIndex >= 1 else {
            return nil
        }
        var site = URLComponents()
        site.scheme = url.scheme
        site.host = url.host
        site.port = url.port
        site.path = segments.prefix(approvalPageIndex - 1).map { "/" + $0 }.joined()
        return site.string
    }
}

private extension ApplicationPasswordSiteMatcher {
    static func siteComponents(_ url: String) -> URLComponents? {
        guard let components = componentsWithDefaultScheme(url),
              (components.user ?? "").isEmpty,
              (components.password ?? "").isEmpty else {
            return nil
        }
        return components
    }

    static func componentsWithDefaultScheme(_ url: String) -> URLComponents? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }
        let withScheme = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = components.host,
              !host.isEmpty else {
            return nil
        }
        return components
    }

    static func comparableHost(of components: URLComponents) -> String {
        let host = (components.host ?? "").lowercased()
        return host.hasPrefix(wwwPrefix) ? String(host.dropFirst(wwwPrefix.count)) : host
    }

    static func isApprovalPageSegment(_ segment: String) -> Bool {
        segment.caseInsensitiveCompare(approvalPage) == .orderedSame
    }

    /// The path as a web server resolves it. Servers such as nginx treat an encoded slash (`%2F`) as a separator,
    /// so each decoded segment is split again on `/` and `\` before `.` and `..` are resolved.
    static func serverPath(of components: URLComponents, resolveDots: Bool = true) -> [String] {
        components.percentEncodedPath
            .split(separator: "/")
            .flatMap { encodedSegment in
                let segment = String(encodedSegment)
                return (segment.removingPercentEncoding ?? segment).split(whereSeparator: { $0 == "/" || $0 == "\\" })
            }
            .reduce(into: [String]()) { resolved, segment in
                switch segment {
                case "." where resolveDots:
                    break
                case ".." where resolveDots:
                    _ = resolved.popLast()
                default:
                    resolved.append(String(segment))
                }
            }
    }
}

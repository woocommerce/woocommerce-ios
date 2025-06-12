
public final class POSProductFilterService {
    public init() {}

    public func fetchAllTags() async throws -> [ProductTag] {
        try await Task.sleep(nanoseconds: 500_000_000) // simulates network delay

        let fakeTag1 = ProductTag(siteID: 0,
                                  tagID: 123,
                                  name: "chairs",
                                  slug: "chairs")
        let fakeTag2 = ProductTag(siteID: 0,
                                  tagID: 124,
                                  name: "Some tables",
                                  slug: "some-tables")
        return [fakeTag1, fakeTag2]
    }
}

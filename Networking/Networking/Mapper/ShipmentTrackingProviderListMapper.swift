struct ShipmentTrackingProviderListMapper: Mapper {
    /// (Attempts) to convert a dictionary into an ShipmentTrackingProviderGroup entity.
    ///
    func map(response: Data) throws -> [ShipmentTrackingProviderGroup] {
        let decoder = JSONDecoder()
        let res =  try decoder.decode([String: [String: String]].self, from: response)

        var providerGroups: [ShipmentTrackingProviderGroup] = []

        let keys = res.keys
        for key in keys {
            let groupName = key
            guard let provider = res[key] else {
                return []
            }

            let providerNames = provider.keys

            var providers: [ShipmentTrackingProvider] = []
            for providerName in providerNames {
                guard let providerUrl = provider[providerName] else {
                    return []
                }

                providers.append(ShipmentTrackingProvider(name: providerName, url: providerUrl))
            }

            providerGroups.append(ShipmentTrackingProviderGroup(name: groupName, providers: providers))
        }

        return providerGroups
    }
}

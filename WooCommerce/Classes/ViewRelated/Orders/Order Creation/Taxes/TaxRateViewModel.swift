import Yosemite

struct TaxRateViewModel {
    let id: Int64
    let title: String
    let rate: String
    let showChevron: Bool
}

extension TaxRateViewModel {
    init(taxRate: TaxRate, showChevron: Bool = true) {
        var title = taxRate.name
        let titleSuffix = "\(taxRate.country) \(taxRate.state) \(taxRate.postcodes.joined(separator: ",")) \(taxRate.cities.joined(separator: ","))"

        if titleSuffix.trimmingCharacters(in: .whitespaces).isNotEmpty {
            title.append(" • \(titleSuffix)")
        }

        self.init(id: taxRate.id,
                  title: title,
                  rate: Double(taxRate.rate)?.percentFormatted() ?? "",
                  showChevron: showChevron)
    }
}

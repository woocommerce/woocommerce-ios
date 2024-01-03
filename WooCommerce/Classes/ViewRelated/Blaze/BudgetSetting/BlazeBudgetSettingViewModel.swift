import Foundation

/// View model for `BlazeBudgetSettingView`
final class BlazeBudgetSettingViewModel: ObservableObject {
    @Published var amount: Double = 5
    @Published var dayCount: Double = 1
    @Published var startDate = Date.now
}

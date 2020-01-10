/// Determines formatting requirements for numerical input string with a unit.
///
protocol UnitInputFormatter {
    /// Determines if the input is valid for the unit.
    ///
    func isValid(input: String) -> Bool

    /// Applies formatting to the given input string.
    ///
    func format(input: String?) -> String
}

import Testing

@testable import CLIACore

@Test("Union.strings preserves order and deduplicates across lists")
func testUnionStringsOrderAndDedup() {
  let first = ["A", "B", "A", "  ", "B"]
  let second = ["B", "C"]
  let third = ["", "D", "A", "E"]

  let merged = Union.strings([first, second, third])

  // Expect stable order (first occurrence wins) and no duplicates or blanks
  #expect(merged == ["A", "B", "C", "D", "E"])
}

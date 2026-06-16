import XCTest
import Defaults
@testable import Retrace

@MainActor
class CommandHistoryItemTests: XCTestCase {
  func testTitleForString() {
    let title = "foo"
    let item = commandHistoryItem(title)
    XCTAssertEqual(item.title, title)
  }

  func testTitleWithWhitespaces() {
    let title = "   foo bar   "
    let item = commandHistoryItem(title)
    XCTAssertEqual(item.title, "···foo bar···")
  }

  func testTitleWithNewlines() {
    let title = "\nfoo\nbar\n"
    let item = commandHistoryItem(title)
    XCTAssertEqual(item.title, "⏎foo⏎bar⏎")
  }

  func testTitleWithTabs() {
    let title = "\tfoo\tbar\t"
    let item = commandHistoryItem(title)
    XCTAssertEqual(item.title, "⇥foo⇥bar⇥")
  }

  func testItemWithoutData() {
    let item = commandHistoryItem(nil)
    XCTAssertEqual(item.title, "")
  }

  private func commandHistoryItem(_ value: String?) -> CommandHistoryItem {
    let item = CommandHistoryItem(command: value)
    item.title = item.generateTitle()

    return item
  }
}

import XCTest
@testable import Retrace

@MainActor
final class NavigationManagerTests: XCTestCase {
  func testNextFromLastCommandDoesNotSelectFooter() {
    let (navigator, history, footer) = makeNavigator()

    navigator.select(item: history.items[1])
    navigator.highlightNext()

    XCTAssertEqual(navigator.selectedCommandItem, history.items[1])
    XCTAssertNil(footer.selectedItem)
  }

  func testLastSelectsLastCommandNotFooter() {
    let (navigator, history, footer) = makeNavigator()

    navigator.select(item: history.items[0])
    navigator.highlightLast()

    XCTAssertEqual(navigator.selectedCommandItem, history.items[1])
    XCTAssertNil(footer.selectedItem)
  }

  private func makeNavigator() -> (
    navigator: NavigationManager,
    history: CommandHistory,
    footer: Footer
  ) {
    let history = CommandHistory()
    history.items = [
      commandHistoryItem("git status"),
      commandHistoryItem("git push")
    ]

    let footer = Footer()
    let navigator = NavigationManager(history: history, footer: footer)
    return (navigator, history, footer)
  }

  private func commandHistoryItem(_ command: String) -> CommandHistoryItemDecorator {
    let item = CommandHistoryItem(command: command)
    item.title = item.generateTitle()
    return CommandHistoryItemDecorator(item)
  }
}

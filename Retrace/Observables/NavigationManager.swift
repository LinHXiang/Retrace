import Foundation
import SwiftUI

@Observable
class NavigationManager {
  private var history: CommandHistory
  private var footer: Footer

  init(history: CommandHistory, footer: Footer) {
    self.history = history
    self.footer = footer
  }

  var selectedCommandItem: CommandHistoryItemDecorator? {
    willSet {
      selectedCommandItem?.isSelected = false
      newValue?.isSelected = true
    }
  }

  var scrollTarget: UUID?
  var leadSelection: UUID? {
    if let item = leadCommandItem {
      return item.id
    }
    if let footerItem = footer.selectedItem {
      return footerItem.id
    }
    return nil
  }
  private(set) var leadCommandItem: CommandHistoryItemDecorator?

  var hoverSelectionWhileKeyboardNavigating: UUID?
  var isKeyboardNavigating: Bool = true {
    didSet {
      if !isKeyboardNavigating,
         let hoverSelection = hoverSelectionWhileKeyboardNavigating {
        hoverSelectionWhileKeyboardNavigating = nil
        select(id: hoverSelection)
      }
    }
  }

  private func scroll(to id: UUID?) {
    scrollTarget = id
  }

  func select(id: UUID) {
    if let item = history.items.first(where: { $0.id == id }) {
      select(item: item, footerItem: nil)
    } else if let item = footer.items.first(where: { $0.id == id }) {
      select(item: nil, footerItem: item)
    } else {
      select(item: nil, footerItem: nil)
    }
  }

  func select(item: CommandHistoryItemDecorator? = nil, footerItem: FooterItem? = nil) {
    withTransaction(Transaction()) {
      selectWithoutScrolling(item: item, footerItem: footerItem)
      scroll(to: item?.id)
    }
  }

  func selectWithoutScrolling(id: UUID) {
    if let item = history.items.first(where: { $0.id == id }) {
      selectWithoutScrolling(item: item, footerItem: nil)
    } else if let item = footer.items.first(where: { $0.id == id }) {
      selectWithoutScrolling(item: nil, footerItem: item)
    } else {
      selectWithoutScrolling(item: nil, footerItem: nil)
    }
  }

  func selectWithoutScrolling(
    item: CommandHistoryItemDecorator? = nil,
    footerItem: FooterItem? = nil
  ) {
    if let item = item {
      selectInCommandHistory(item)
    } else if let footerItem = footerItem {
      selectInFooter(footerItem)
    } else {
      leadCommandItem = nil
      selectedCommandItem = nil
      footer.selectedItem = nil
    }
  }

  private func selectInCommandHistory(_ item: CommandHistoryItemDecorator) {
    leadCommandItem = item
    selectedCommandItem = item
    footer.selectedItem = nil
  }

  private func selectInFooter(_ item: FooterItem) {
    leadCommandItem = nil
    selectedCommandItem = nil
    footer.selectedItem = item
  }

  private func selectFromKeyboardNavigation(
    item: CommandHistoryItemDecorator? = nil,
    footerItem: FooterItem? = nil
  ) {
    isKeyboardNavigating = true
    select(item: item, footerItem: footerItem)
  }

  func highlightFirst() {
    if let item = history.firstVisibleItem {
      selectFromKeyboardNavigation(item: item)
    } else {
      selectFromKeyboardNavigation(item: nil)
    }
  }

  func highlightPrevious() {
    guard let lead = leadSelection else { return }

    if let historyItem = history.firstVisibleItem(where: { $0.id == lead }) {
      if let nextItem = history.visibleItem(before: historyItem) {
        selectFromKeyboardNavigation(item: nextItem)
      } else {
        highlightFirst()
      }
    } else if let footerItem = footer.firstVisibleItem(where: { $0.id == lead }) {
      if let nextItem = footer.visibleItem(before: footerItem) {
        selectFromKeyboardNavigation(footerItem: nextItem)
      } else if let nextItem = history.lastVisibleItem {
        selectFromKeyboardNavigation(item: nextItem)
      }
    }
  }

  func highlightNext(allowCycle: Bool = false) {
    guard let lead = leadSelection else { return }

    if let historyItem = history.firstVisibleItem(where: { $0.id == lead }) {
      if let nextItem = history.visibleItem(after: historyItem) {
        selectFromKeyboardNavigation(item: nextItem)
      } else if let nextItem = footer.firstVisibleItem {
        selectFromKeyboardNavigation(footerItem: nextItem)
      } else if allowCycle {
        highlightFirst()
      }
    } else if let footerItem = footer.firstVisibleItem(where: { $0.id == lead }) {
      if let nextItem = footer.visibleItem(after: footerItem) {
        selectFromKeyboardNavigation(footerItem: nextItem)
      } else if let nextItem = footer.firstVisibleItem {
        selectFromKeyboardNavigation(footerItem: nextItem)
      } else if allowCycle {
        // End of footer; cycle to the beginning
        highlightFirst()
      }
    }
  }

  func highlightLast() {
    guard let lead = leadSelection else { return }

    if let historyItem = history.firstVisibleItem(where: { $0.id == lead }) {
      if historyItem == history.lastVisibleItem,
         let nextItem = footer.firstVisibleItem {
        selectFromKeyboardNavigation(footerItem: nextItem)
      } else {
        selectFromKeyboardNavigation(item: history.lastVisibleItem)
      }
    } else if footer.selectedItem != nil {
      selectFromKeyboardNavigation(footerItem: footer.lastVisibleItem)
    } else {
      selectFromKeyboardNavigation(footerItem: footer.firstVisibleItem)
    }
  }

}

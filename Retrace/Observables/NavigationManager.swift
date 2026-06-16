import Foundation
import SwiftUI

@Observable
class NavigationManager { // swiftlint:disable:this type_body_length
  private var history: History
  private var footer: Footer

  init(history: History, footer: Footer) {
    self.history = history
    self.footer = footer
  }

  var selection: Selection<HistoryItemDecorator> = Selection() {
    willSet {
      selection.forEach { item in item.isSelected = false }
      newValue.forEach { item in item.isSelected = true }
    }
  }

  var scrollTarget: UUID?
  var leadSelection: UUID? {
    if let item = leadHistoryItem {
      return item.id
    }
    if let footerItem = footer.selectedItem {
      return footerItem.id
    }
    return nil
  }
  private(set) var leadHistoryItem: HistoryItemDecorator?

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

  private func scroll(to id: UUID?, item: HistoryItemDecorator? = nil) {
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

  func select(item: HistoryItemDecorator? = nil, footerItem: FooterItem? = nil) {
    withTransaction(Transaction()) {
      selectWithoutScrolling(item: item, footerItem: footerItem)
      scroll(to: item?.id, item: item)
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
    item: HistoryItemDecorator? = nil,
    footerItem: FooterItem? = nil
  ) {
    if let item = item {
      selectInHistory(item)
    } else if let footerItem = footerItem {
      selectInFooter(footerItem)
    } else {
      leadHistoryItem = nil
      selection = .init()
      footer.selectedItem = nil
    }
  }

  private func selectInHistory(_ item: HistoryItemDecorator) {
    leadHistoryItem = item
    selection = .init(item)
    footer.selectedItem = nil
  }

  private func selectInFooter(_ item: FooterItem) {
    leadHistoryItem = nil
    selection = .init()
    footer.selectedItem = item
  }

  private func selectFromKeyboardNavigation(
    item: HistoryItemDecorator? = nil,
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

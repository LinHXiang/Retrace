extension Collection where Element: Equatable {
  func item(after: Element, where predicate: (Element) -> Bool) -> Element? {
    guard let currentIndex = firstIndex(of: after) else {
      return nil
    }

    var nextIndex = index(currentIndex, offsetBy: 1)
    while nextIndex < endIndex {
      let item = self[nextIndex]
      if predicate(item) {
        return item
      }
      nextIndex = index(nextIndex, offsetBy: 1)
    }
    return nil
  }

  func item(before: Element, where predicate: (Element) -> Bool) -> Element? {
    guard let currentIndex = firstIndex(of: before) else {
      return nil
    }

    var prevIndex = index(currentIndex, offsetBy: -1)
    while prevIndex >= startIndex {
      let item = self[prevIndex]
      if predicate(item) {
        return item
      }
      prevIndex = index(prevIndex, offsetBy: -1)
    }
    return nil
  }

}

struct Selection<Item> {
  var item: Item?

  init(_ item: Item? = nil) {
    self.item = item
  }

  var isEmpty: Bool {
    return item == nil
  }

  var first: Item? {
    return item
  }

  func forEach(_ body: (Item) throws -> Void) rethrows {
    if let item {
      try body(item)
    }
  }
}

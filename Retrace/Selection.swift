struct Selection<Item: Equatable> {
  var items: [Item]

  init(items: [Item] = []) {
    self.items = items
  }

  var isEmpty: Bool {
    return items.isEmpty
  }

  var first: Item? {
    return items.first
  }

  func first(where condition: (Item) -> Bool) -> Item? {
    return items.first(where: condition)
  }

  func forEach(_ body: (Item) throws -> Void) rethrows {
    try items.forEach(body)
  }
}

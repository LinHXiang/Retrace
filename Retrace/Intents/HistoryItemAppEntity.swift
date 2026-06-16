import AppIntents

struct HistoryItemAppEntity: TransientAppEntity {
  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Terminal command")

  @Property(title: "Text")
  var text: String?

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "Terminal command")
  }
}

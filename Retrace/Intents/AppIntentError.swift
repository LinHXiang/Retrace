import Foundation

enum AppIntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
  case notFound

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .notFound: return "Command not found"
    }
  }
}

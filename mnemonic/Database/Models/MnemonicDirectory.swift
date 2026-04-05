import GRDB
import Foundation

nonisolated struct MnemonicDirectory: Codable, Identifiable, Sendable {
  var id: Int64?
  var path: String
  var label: String?
  var watch: Bool
  var addedAt: Date
  var lastIndexedAt: Date?
  var bookmark: Data?
}

nonisolated extension MnemonicDirectory: FetchableRecord, MutablePersistableRecord {
  static let databaseTableName = "directories"
  mutating func didInsert(_ inserted: InsertionSuccess) {
    id = inserted.rowID
  }
}

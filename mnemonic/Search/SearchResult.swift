import Foundation

nonisolated struct SearchResult: Identifiable, Sendable {
  let id: Int64
  let filename: String
  let path: String
  let thumbnailPath: String?
  let rawScore: Float
  let relevance: Float
  
  enum RelevanceTier {
    case high, medium, low
  }
  
  var tier: RelevanceTier {
    if relevance >= 0.70 { return .high }
    if relevance >= 0.45 { return .medium }
    return .low
  }
}

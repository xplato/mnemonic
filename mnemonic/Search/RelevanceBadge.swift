import SwiftUI

struct RelevanceBadge: View {
  let relevance: Float
  
  private var color: Color {
    if relevance >= 0.70 { return .green }
    if relevance >= 0.45 { return .yellow }
    return .gray
  }
  
  var body: some View {
    Text("\(Int(relevance * 100))%")
      .font(.caption2.weight(.medium))
      .padding(.horizontal, 5)
      .padding(.vertical, 2)
      .background(color.opacity(0.2))
      .foregroundStyle(color)
      .clipShape(Capsule())
  }
}

import Foundation

struct SearchItem: Identifiable, Codable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String

//    init(id: UUID = UUID(), title: String, subtitle: String, icon: String) {
//      self.id = id
//      self.title = title
//      self.subtitle = subtitle
//      self.icon = icon
//    }
}

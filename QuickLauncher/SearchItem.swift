import Foundation

struct SearchItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
}

extension SearchItem {
    static let mockItems = [
        SearchItem(title: "Visual Studio Code", subtitle: "Editor de código", icon: "chevron.left.forwardslash.chevron.right"),
        SearchItem(title: "Chrome", subtitle: "Navegador web", icon: "globe"),
        SearchItem(title: "Slack", subtitle: "Comunicação", icon: "message"),
        SearchItem(title: "Terminal", subtitle: "Terminal", icon: "terminal"),
        SearchItem(title: "Notes", subtitle: "Notas", icon: "note.text"),
        SearchItem(title: "Calendar", subtitle: "Calendário", icon: "calendar"),
        SearchItem(title: "Mail", subtitle: "Email", icon: "envelope"),
    ]
}
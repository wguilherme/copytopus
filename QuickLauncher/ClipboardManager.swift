import SwiftUI
import Foundation

class ClipboardManager: ObservableObject {
    @Published var clipboardHistory: [SearchItem] = []
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxItems = 100  // Limite máximo de itens no histórico
    
    init() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        loadHistory()
        startMonitoring()
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    private func checkForChanges() {
        let currentCount = NSPasteboard.general.changeCount
        guard currentCount > lastChangeCount else { return }
        
        lastChangeCount = currentCount
        
        guard let newString = NSPasteboard.general.string(forType: .string) else { return }
        
        // Evita duplicatas consecutivas
        if let lastItem = clipboardHistory.first, lastItem.title == newString {
            return
        }
        
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        DispatchQueue.main.async {
            let newItem = SearchItem(
                title: newString,
                subtitle: "Copiado em \(dateFormatter.string(from: timestamp))",
                icon: "doc.on.clipboard"
            )
            
            self.clipboardHistory.insert(newItem, at: 0)
            
            // Mantém apenas os últimos maxItems itens
            if self.clipboardHistory.count > self.maxItems {
                self.clipboardHistory.removeLast()
            }
            
            // Salva o histórico
            self.saveHistory()
        }
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(clipboardHistory) {
            UserDefaults.standard.set(encoded, forKey: "clipboardHistory")
        }
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "clipboardHistory"),
           let decoded = try? JSONDecoder().decode([SearchItem].self, from: data) {
            clipboardHistory = decoded
        }
    }
    
    func clearHistory() {
        clipboardHistory.removeAll()
        saveHistory()
    }
    
    deinit {
        timer?.invalidate()
    }
}
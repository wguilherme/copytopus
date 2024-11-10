import SwiftUI
import Foundation

class ClipboardManager: ObservableObject {
    @Published var clipboardHistory: [SearchItem] = []
    private var lastChangeCount: Int
    private var timer: Timer?
    private let maxItems = 100
    
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
        
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        DispatchQueue.main.async {
            // Se encontrar um item existente, remove ele da posição atual
            if let existingIndex = self.clipboardHistory.firstIndex(where: { $0.title == newString }) {
                let existingItem = self.clipboardHistory.remove(at: existingIndex)
                // Atualiza o timestamp do item existente
                let updatedItem = SearchItem(
                    title: existingItem.title,
                    subtitle: "Copiado em \(dateFormatter.string(from: timestamp))",
                    icon: existingItem.icon
                )
                self.clipboardHistory.insert(updatedItem, at: 0)
            } else {
                // Se não existir, cria um novo item
                let newItem = SearchItem(
                    title: newString,
                    subtitle: "Copiado em \(dateFormatter.string(from: timestamp))",
                    icon: "doc.on.clipboard"
                )
                self.clipboardHistory.insert(newItem, at: 0)
                
                if self.clipboardHistory.count > self.maxItems {
                    self.clipboardHistory.removeLast()
                }
            }
            
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

    func deleteItem(at index: Int) {
        guard index >= 0 && index < clipboardHistory.count else { return }
        DispatchQueue.main.async {
            self.clipboardHistory.remove(at: index)
            self.saveHistory()
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

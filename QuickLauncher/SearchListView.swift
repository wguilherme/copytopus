import SwiftUI

struct SearchListView: View {
    let items: [SearchItem]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { item in
                SearchItemRow(item: item)
                
                if item.id != items.last?.id {
                    Divider()
                        .padding(.leading, 36)
                }
            }
        }
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct SearchItemRow: View {
    let item: SearchItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .frame(width: 20)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .fontWeight(.medium)
                
                Text(item.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .contentShape(Rectangle())
        .highPriorityGesture(TapGesture().onEnded {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.title, forType: .string)
            print("Clicou em: \(item.title)")
        })
    }
}

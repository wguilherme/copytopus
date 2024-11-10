import SwiftUI

struct SearchListView: View {
    let items: [SearchItem]
    let selectedIndex: Int?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        SearchItemRow(
                            item: item,
                            isSelected: index == selectedIndex
                        )
                        .id(index)                         
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 36)
                        }
                    }
                }
            }
            .onChange(of: selectedIndex) { oldValue, newValue in
                if let index = newValue {
                    withAnimation {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
        }
        .frame(minHeight: 500, maxHeight: 700)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct SearchItemRow: View {
    let item: SearchItem
    let isSelected: Bool
    
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
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .contentShape(Rectangle())
        .highPriorityGesture(TapGesture().onEnded {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.title, forType: .string)
            print("Copiado para área de transferência: \(item.title)")
        })
    }
}
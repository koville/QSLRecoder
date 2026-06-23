import SwiftUI
import SwiftData

struct RepeaterListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Repeater.name) private var repeaters: [Repeater]

    @State private var showingAddRepeater = false
    @State private var selectedRepeater: Repeater?
    @State private var filterFavoritesOnly = false

    var filteredRepeaters: [Repeater] {
        filterFavoritesOnly ? repeaters.filter(\.isFavorite) : repeaters
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("过滤", selection: $filterFavoritesOnly) {
                Text("全部").tag(false)
                Text("已收藏").tag(true)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                ForEach(filteredRepeaters) { repeater in
                    RepeaterRowView(repeater: repeater)
                        .contentShape(Rectangle())
                        .onTapGesture { selectedRepeater = repeater }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                modelContext.delete(repeater)
                                try? modelContext.save()
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                repeater.isFavorite.toggle()
                                repeater.updatedAt = Date()
                                try? modelContext.save()
                            } label: {
                                Label(
                                    repeater.isFavorite ? "取消收藏" : "收藏",
                                    systemImage: repeater.isFavorite ? "star.slash" : "star"
                                )
                            }
                            .tint(.yellow)
                        }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("中继台")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAddRepeater = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddRepeater) {
            RepeaterEditView(repeater: nil)
        }
        .sheet(item: $selectedRepeater) { repeater in
            RepeaterEditView(repeater: repeater)
        }
    }
}

struct RepeaterRowView: View {
    let repeater: Repeater

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .foregroundColor(.blue)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(repeater.name.isEmpty ? "未命名" : repeater.name)
                        .font(.headline)
                    if repeater.isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }

                if !repeater.callsign.isEmpty {
                    Text(repeater.callsign)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 2) {
                    Text("↓")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatFreq(repeater.downlinkFreq))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                HStack(spacing: 2) {
                    Text("↑")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatFreq(repeater.uplinkFreq))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(repeater.mode)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatFreq(_ mhz: Double) -> String {
        mhz > 0 ? String(format: "%.4f MHz", mhz) : "-"
    }
}

#Preview {
    NavigationStack {
        RepeaterListView()
    }
}
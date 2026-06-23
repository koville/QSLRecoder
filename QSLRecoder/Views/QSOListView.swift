import SwiftUI
import SwiftData

struct QSOListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<QSO> { !$0.isDeleted }, sort: \QSO.datetimeOn, order: .reverse) private var qsoList: [QSO]
    
    @State private var searchText = ""
    @State private var showingAddQSO = false
    @State private var selectedQSO: QSO?
    @State private var filterMode = FilterMode.all
    @State private var sortOrder = SortOrder.dateDesc
    @State private var selectedQSOs = Set<UUID>()
    @State private var isMultiSelect = false
    
    enum FilterMode: String, CaseIterable {
        case all = "全部"
        case unconfirmed = "未确认"
        case confirmed = "已确认"
        case thisMonth = "本月"
        case pendingQSL = "待发送QSL"
    }
    
    enum SortOrder: String, CaseIterable {
        case dateDesc = "最新优先"
        case dateAsc = "最早优先"
        case callsignAsc = "呼号升序"
        case callsignDesc = "呼号降序"
        case bandAsc = "频段升序"
    }
    
    var filteredQSOs: [QSO] {
        var result = qsoList
        
        // Apply filter
        switch filterMode {
        case .all:
            break
        case .unconfirmed:
            result = result.filter { $0.qslSent == .no || $0.qslRcvd == .no }
        case .confirmed:
            result = result.filter { $0.qslSent == .yes && $0.qslRcvd == .yes }
        case .thisMonth:
            let calendar = Calendar.current
            let now = Date()
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth)!
            result = result.filter { $0.datetimeOn >= startOfMonth && $0.datetimeOn <= endOfMonth }
        case .pendingQSL:
            result = result.filter { $0.qslSent == .no }
        }
        
        // Apply search
        if !searchText.isEmpty {
            result = result.filter { 
                $0.callsign.localizedCaseInsensitiveContains(searchText) ||
                $0.country.localizedCaseInsensitiveContains(searchText) ||
                $0.mode.localizedCaseInsensitiveContains(searchText) ||
                $0.band.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply sort
        switch sortOrder {
        case .dateDesc:
            result.sort { $0.datetimeOn > $1.datetimeOn }
        case .dateAsc:
            result.sort { $0.datetimeOn < $1.datetimeOn }
        case .callsignAsc:
            result.sort { $0.callsign < $1.callsign }
        case .callsignDesc:
            result.sort { $0.callsign > $1.callsign }
        case .bandAsc:
            result.sort { $0.band < $1.band }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter bar
            filterBar
            
            // List
            if isMultiSelect {
                multiSelectList
            } else {
                qsoListContent
            }
        }
        .navigationTitle("通联日志")
        .searchable(text: $searchText, prompt: "搜索呼号、国家、模式...")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { isMultiSelect.toggle() }) {
                    Text(isMultiSelect ? "完成" : "选择")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: { showingAddQSO = true }) {
                        Label("新增通联", systemImage: "plus")
                    }
                    Button(action: importADIF) {
                        Label("导入ADIF", systemImage: "square.and.arrow.down")
                    }
                    Button(action: exportADIF) {
                        Label("导出ADIF", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddQSO) {
            QSOEditView(qso: nil)
        }
        .sheet(item: $selectedQSO) { qso in
            QSOEditView(qso: qso)
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(FilterMode.allCases, id: \.self) { mode in
                    Button(action: { filterMode = mode }) {
                        Text(mode.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(filterMode == mode ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(filterMode == mode ? .white : .primary)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(action: { sortOrder = order }) {
                            Label(order.rawValue, systemImage: sortOrder == order ? "checkmark" : "")
                        }
                    }
                } label: {
                    Label("排序", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    private var qsoListContent: some View {
        List {
            ForEach(filteredQSOs) { qso in
                QSORowView(qso: qso)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedQSO = qso
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteQSO(qso)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
    
    private var multiSelectList: some View {
        List(selection: $selectedQSOs) {
            ForEach(filteredQSOs) { qso in
                HStack {
                    Image(systemName: selectedQSOs.contains(qso.id) ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(selectedQSOs.contains(qso.id) ? .blue : .gray)
                    QSORowView(qso: qso)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedQSOs.contains(qso.id) {
                        selectedQSOs.remove(qso.id)
                    } else {
                        selectedQSOs.insert(qso.id)
                    }
                }
            }
        }
        .listStyle(.plain)
        .overlay(alignment: .bottom) {
            if !selectedQSOs.isEmpty {
                HStack {
                    Button(role: .destructive) {
                        deleteSelectedQSOs()
                    } label: {
                        Label("删除 (\(selectedQSOs.count))", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    
                    Button {
                        batchUpdateQSLStatus()
                    } label: {
                        Label("批量修改QSL", systemImage: "envelope.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }
    
    private func deleteQSO(_ qso: QSO) {
        qso.isDeleted = true
        qso.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func deleteSelectedQSOs() {
        for qso in qsoList where selectedQSOs.contains(qso.id) {
            qso.isDeleted = true
            qso.updatedAt = Date()
        }
        try? modelContext.save()
        selectedQSOs.removeAll()
        isMultiSelect = false
    }
    
    private func batchUpdateQSLStatus() {
        // Show batch update sheet
    }
    
    private func importADIF() {
        // Trigger ADIF import
    }
    
    private func exportADIF() {
        // Trigger ADIF export
    }
}

struct QSORowView: View {
    let qso: QSO
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(qso.callsign)
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    if qso.qslSent == .yes && qso.qslRcvd == .yes {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                Text(qso.country.isEmpty ? "未知地区" : qso.country)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !qso.repeaterName.isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 9))
                        Text(qso.repeaterName)
                            .font(.system(size: 9))
                    }
                    .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(qso.band.isEmpty ? "未知频段" : qso.band)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(qso.mode)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(qso.datetimeOn, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        QSOListView()
    }
}

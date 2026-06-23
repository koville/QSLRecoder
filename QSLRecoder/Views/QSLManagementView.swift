import SwiftUI
import SwiftData

struct QSLManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \QSLBatch.sendDate, order: .reverse) private var batches: [QSLBatch]
    @Query(filter: #Predicate<QSO> { !$0.isDeleted }) private var allQSOs: [QSO]
    
    @State private var showingNewBatch = false
    @State private var selectedBatch: QSLBatch?
    @State private var viewMode = ViewMode.batches
    
    enum ViewMode: String, CaseIterable {
        case batches = "发送批次"
        case pending = "待处理"
        case tracking = "状态追踪"
    }
    
    var pendingQSOs: [QSO] {
        allQSOs.filter { $0.qslSent == .no || $0.qslRcvd == .no }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // View mode picker
            Picker("视图模式", selection: $viewMode) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            // Content
            switch viewMode {
            case .batches:
                batchesView
            case .pending:
                pendingView
            case .tracking:
                trackingView
            }
        }
        .navigationTitle("QSL卡片")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewBatch = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewBatch) {
            QSLBatchEditView(batch: nil)
        }
        .sheet(item: $selectedBatch) { batch in
            QSLBatchEditView(batch: batch)
        }
    }
    
    private var batchesView: some View {
        List {
            if batches.isEmpty {
                ContentUnavailableView {
                    Label("暂无发送批次", systemImage: "envelope")
                } description: {
                    Text("创建批次来组织和管理待发送的QSL卡片")
                } actions: {
                    Button("创建批次") {
                        showingNewBatch = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                ForEach(batches) { batch in
                    QSLBatchRowView(batch: batch)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBatch = batch
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                deleteBatch(batch)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .listStyle(.plain)
    }
    
    private var pendingView: some View {
        List {
            if pendingQSOs.isEmpty {
                ContentUnavailableView {
                    Label("没有待处理的QSL", systemImage: "checkmark.circle")
                } description: {
                    Text("所有QSL卡片都已处理完成")
                }
            } else {
                Section("待发送 (\(pendingQSOs.filter { $0.qslSent == .no }.count))") {
                    ForEach(pendingQSOs.filter { $0.qslSent == .no }) { qso in
                        QSORowView(qso: qso)
                            .swipeActions {
                                Button {
                                    markQSLSent(qso)
                                } label: {
                                    Label("标记已发送", systemImage: "paperplane.fill")
                                }
                                .tint(.blue)
                            }
                    }
                }
                
                Section("待确认 (\(pendingQSOs.filter { $0.qslRcvd == .no && $0.qslSent == .yes }.count))") {
                    ForEach(pendingQSOs.filter { $0.qslRcvd == .no && $0.qslSent == .yes }) { qso in
                        QSORowView(qso: qso)
                            .swipeActions {
                                Button {
                                    markQSLReceived(qso)
                                } label: {
                                    Label("标记已收到", systemImage: "checkmark")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private var trackingView: some View {
        List {
            let sentCount = allQSOs.filter { $0.qslSent == .yes }.count
            let rcvdCount = allQSOs.filter { $0.qslRcvd == .yes }.count
            let confirmedCount = allQSOs.filter { $0.qslSent == .yes && $0.qslRcvd == .yes }.count
            
            Section("统计概览") {
                LabeledContent("总通联数", value: "\(allQSOs.count)")
                LabeledContent("已发送", value: "\(sentCount)")
                LabeledContent("已收到", value: "\(rcvdCount)")
                LabeledContent("已确认", value: "\(confirmedCount)")
                
                if allQSOs.count > 0 {
                    let sendRate = Double(sentCount) / Double(allQSOs.count) * 100
                    let rcvdRate = sentCount > 0 ? Double(rcvdCount) / Double(sentCount) * 100 : 0
                    let confirmRate = Double(confirmedCount) / Double(allQSOs.count) * 100
                    
                    LabeledContent("发送率", value: String(format: "%.1f%%", sendRate))
                    LabeledContent("回收率", value: String(format: "%.1f%%", rcvdRate))
                    LabeledContent("确认率", value: String(format: "%.1f%%", confirmRate))
                }
            }
            
            Section("按发送方式") {
                ForEach(BatchVia.allCases, id: \.self) { via in
                    let count = allQSOs.filter { $0.qslVia == via.rawValue }.count
                    LabeledContent(via.rawValue, value: "\(count)")
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteBatch(_ batch: QSLBatch) {
        modelContext.delete(batch)
        try? modelContext.save()
    }
    
    private func markQSLSent(_ qso: QSO) {
        qso.qslSent = .yes
        qso.qslSentDate = Date()
        qso.updatedAt = Date()
        try? modelContext.save()
    }
    
    private func markQSLReceived(_ qso: QSO) {
        qso.qslRcvd = .yes
        qso.qslRcvdDate = Date()
        qso.updatedAt = Date()
        try? modelContext.save()
    }
}

struct QSLBatchRowView: View {
    let batch: QSLBatch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(batch.name.isEmpty ? "未命名片次" : batch.name)
                    .font(.headline)
                
                Spacer()
                
                Text(batch.status.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 16) {
                Label(batch.destination.isEmpty ? "未指定" : batch.destination, systemImage: "location")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label(batch.via.rawValue, systemImage: "paperplane")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Label("\(batch.qsoRecords.count) 张", systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(batch.sendDate, style: .date)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch batch.status {
        case .pending: return .orange
        case .sent: return .blue
        case .completed: return .green
        }
    }
}

#Preview {
    NavigationStack {
        QSLManagementView()
    }
}

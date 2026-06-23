import SwiftUI
import SwiftData

struct QSLBatchEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let batch: QSLBatch?
    
    @State private var name = ""
    @State private var destination = ""
    @State private var via = BatchVia.bureau
    @State private var sendDate = Date()
    @State private var status = BatchStatus.pending
    @State private var remark = ""
    @State private var selectedQSOs = Set<UUID>()
    
    @Query(filter: #Predicate<QSO> { !$0.isDeleted }, sort: \QSO.datetimeOn, order: .reverse) private var allQSOs: [QSO]
    
    var isEditing: Bool { batch != nil }
    
    var availableQSOs: [QSO] {
        allQSOs.filter { $0.qslSent == .no }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("批次信息") {
                    TextField("批次名称", text: $name)
                    TextField("目的地", text: $destination)
                    
                    Picker("发送方式", selection: $via) {
                        ForEach(BatchVia.allCases, id: \.self) { via in
                            Text(via.rawValue).tag(via)
                        }
                    }
                    
                    DatePicker("发送日期", selection: $sendDate, displayedComponents: .date)
                    
                    Picker("状态", selection: $status) {
                        ForEach(BatchStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                
                Section("备注") {
                    TextEditor(text: $remark)
                        .frame(minHeight: 60)
                }
                
                Section("选择通联记录 (\(selectedQSOs.count))") {
                    if availableQSOs.isEmpty {
                        Text("没有待发送的通联记录")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(availableQSOs) { qso in
                            HStack {
                                Image(systemName: selectedQSOs.contains(qso.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedQSOs.contains(qso.id) ? .blue : .gray)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(qso.callsign)
                                        .font(.headline)
                                    Text("\(qso.band) \(qso.mode) - \(qso.datetimeOn.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleQSO(qso)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑批次" : "新增批次")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveBatch()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                loadBatchData()
            }
        }
    }
    
    private func loadBatchData() {
        guard let batch = batch else { return }
        
        name = batch.name
        destination = batch.destination
        via = batch.via
        sendDate = batch.sendDate
        status = batch.status
        remark = batch.remark
        selectedQSOs = Set(batch.qsoRecords.map { $0.id })
    }
    
    private func toggleQSO(_ qso: QSO) {
        if selectedQSOs.contains(qso.id) {
            selectedQSOs.remove(qso.id)
        } else {
            selectedQSOs.insert(qso.id)
        }
    }
    
    private func saveBatch() {
        let qsoRecords = allQSOs.filter { selectedQSOs.contains($0.id) }
        
        if let batch = batch {
            // Update existing
            batch.name = name
            batch.destination = destination
            batch.via = via
            batch.sendDate = sendDate
            batch.status = status
            batch.remark = remark
            batch.qsoRecords = qsoRecords
            batch.updatedAt = Date()
        } else {
            // Create new
            let newBatch = QSLBatch(
                name: name,
                destination: destination,
                via: via,
                sendDate: sendDate,
                status: status,
                remark: remark,
                qsoRecords: qsoRecords
            )
            modelContext.insert(newBatch)
            
            // Update QSO QSL status
            for qso in qsoRecords {
                qso.qslSent = .requested
                qso.updatedAt = Date()
            }
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    QSLBatchEditView(batch: nil)
}

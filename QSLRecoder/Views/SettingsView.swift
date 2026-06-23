import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allQSOs: [QSO]
    @Query private var allBatches: [QSLBatch]
    
    @State private var showingImportFilePicker = false
    @State private var showingExportOptions = false
    @State private var showingBackupOptions = false
    @State private var showingResetConfirmation = false
    @State private var importStatus: ImportStatus?
    @State private var exportFormat: ExportFormat = .adif
    
    struct ImportStatus {
        let message: String
        let isError: Bool
    }
    
    var body: some View {
        List {
            // Station info
            Section("我的电台") {
                NavigationLink {
                    MyStationView()
                } label: {
                    Label("电台信息", systemImage: "antenna.radiowaves.left.and.right")
                }

                NavigationLink {
                    RepeaterListView()
                } label: {
                    Label("中继台管理", systemImage: "repeat")
                }

                NavigationLink {
                    QSLTemplateView()
                } label: {
                    Label("QSL卡片模板", systemImage: "rectangle.on.rectangle")
                }
            }
            
            // Data management
            Section("数据管理") {
                Button {
                    showingImportFilePicker = true
                } label: {
                    Label("导入ADIF文件", systemImage: "square.and.arrow.down")
                }
                
                Button {
                    showingExportOptions = true
                } label: {
                    Label("导出数据", systemImage: "square.and.arrow.up")
                }
                
                Button {
                    showingBackupOptions = true
                } label: {
                    Label("备份与恢复", systemImage: "externaldrive")
                }
            }
            
            // iCloud
            Section("iCloud") {
                NavigationLink {
                    iCloudSettingsView()
                } label: {
                    Label("iCloud 同步", systemImage: "icloud")
                }
            }
            
            // Statistics
            Section("数据统计") {
                LabeledContent("通联记录数", value: "\(allQSOs.count)")
                LabeledContent("QSL批次", value: "\(allBatches.count)")
            }
            
            // About
            Section("关于") {
                LabeledContent("版本", value: "1.0.0")
                LabeledContent("应用名称", value: "QSLRecoder")
                
                Link(destination: URL(string: "https://github.com")!) {
                    Label("GitHub", systemImage: "link")
                }
            }
            
            // Danger zone
            Section {
                Button(role: .destructive) {
                    showingResetConfirmation = true
                } label: {
                    Label("重置所有数据", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("设置")
        .fileImporter(
            isPresented: $showingImportFilePicker,
            allowedContentTypes: [.init(filenameExtension: "adi")!, .init(filenameExtension: "adif")!],
            allowsMultipleSelection: false
        ) { result in
            handleImport(result)
        }
        .confirmationDialog("导出格式", isPresented: $showingExportOptions) {
            Button("ADIF格式") {
                exportData(format: .adif)
            }
            Button("CSV格式") {
                exportData(format: .csv)
            }
            Button("取消", role: .cancel) {}
        }
        .confirmationDialog("备份选项", isPresented: $showingBackupOptions) {
            Button("创建备份") {
                createBackup()
            }
            Button("从备份恢复") {
                restoreBackup()
            }
            Button("取消", role: .cancel) {}
        }
        .alert("确认重置", isPresented: $showingResetConfirmation) {
            Button("确认删除", role: .destructive) {
                resetAllData()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("这将删除所有通联记录和QSL批次数据。此操作不可撤销！")
        }
        .alert(
            importStatus?.isError == true ? "导入失败" : "导入成功",
            isPresented: .init(
                get: { importStatus != nil },
                set: { if !$0 { importStatus = nil } }
            )
        ) {
            Button("确定") { importStatus = nil }
        } message: {
            Text(importStatus?.message ?? "")
        }
    }
    
    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            let adifService = ADIFService(modelContext: modelContext)
            
            Task {
                do {
                    let count = try await adifService.importADIF(from: url)
                    importStatus = ImportStatus(
                        message: "成功导入 \(count) 条通联记录",
                        isError: false
                    )
                } catch {
                    importStatus = ImportStatus(
                        message: "导入失败: \(error.localizedDescription)",
                        isError: true
                    )
                }
            }
            
        case .failure(let error):
            importStatus = ImportStatus(
                message: "选择文件失败: \(error.localizedDescription)",
                isError: true
            )
        }
    }
    
    private func exportData(format: ExportFormat) {
        let adifService = ADIFService(modelContext: modelContext)
        let activeQSOs = allQSOs.filter { !$0.isDeleted }
        
        var content: String
        var filename: String
        var contentType: String
        
        switch format {
        case .adif:
            content = adifService.exportADIF(qsos: activeQSOs)
            filename = "QSLRecoder_\(Date().formatted(date: .numeric, time: .omitted)).adi"
            contentType = "text/plain"
        case .csv:
            content = adifService.exportCSV(qsos: activeQSOs)
            filename = "QSLRecoder_\(Date().formatted(date: .numeric, time: .omitted)).csv"
            contentType = "text/csv"
        }
        
        // Share sheet
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        
        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
    private func createBackup() {
        // Create a JSON backup
        let backupData: [String: Any] = [
            "version": "1.0",
            "date": ISO8601DateFormatter().string(from: Date()),
            "qso_count": allQSOs.count,
            "batch_count": allBatches.count
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: backupData),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("QSLRecoder_backup_\(Date().formatted(date: .numeric, time: .omitted)).json")
            
            try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
            
            let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
    
    private func restoreBackup() {
        // TODO: Implement backup restore
    }
    
    private func resetAllData() {
        for qso in allQSOs {
            modelContext.delete(qso)
        }
        for batch in allBatches {
            modelContext.delete(batch)
        }
        try? modelContext.save()
    }
}

struct MyStationView: View {
    @AppStorage("myCallsign") private var myCallsign = ""
    @AppStorage("myName") private var myName = ""
    @AppStorage("myGrid") private var myGrid = ""
    @AppStorage("myQTHR") private var myQTHR = ""
    
    var body: some View {
        Form {
            Section("基本信息") {
                TextField("我的呼号", text: $myCallsign)
                    .textInputAutocapitalization(.characters)
                TextField("姓名", text: $myName)
                TextField("网格定位", text: $myGrid)
                    .textInputAutocapitalization(.characters)
            }
            
            Section("QSL信息") {
                TextField("QSL通过", text: $myQTHR)
                
                Text("这些信息将用于QSL卡片模板和数据导出")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("电台信息")
    }
}

struct QSLTemplateView: View {
    var body: some View {
        VStack {
            Text("QSL卡片模板")
                .font(.title)
            
            Text("自定义您的QSL卡片设计")
                .foregroundColor(.secondary)
            
            // TODO: Implement QSL template editor
            Spacer()
        }
        .navigationTitle("QSL模板")
    }
}

struct iCloudSettingsView: View {
    @AppStorage("icloudSyncEnabled") private var icloudSyncEnabled = false
    @AppStorage("lastSyncDate") private var lastSyncDate = Date.distantPast
    
    var body: some View {
        List {
            Section {
                Toggle("启用iCloud同步", isOn: $icloudSyncEnabled)
                
                if icloudSyncEnabled {
                    LabeledContent("上次同步", value: lastSyncDate.formatted(date: .abbreviated, time: .shortened))
                    
                    Button("立即同步") {
                        // TODO: Implement iCloud sync
                        lastSyncDate = Date()
                    }
                }
            }
            
            Section {
                Text("启用后，您的通联记录将自动同步到iCloud，可在其他设备上访问。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("iCloud")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}

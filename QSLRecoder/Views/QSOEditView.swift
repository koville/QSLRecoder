import SwiftUI
import SwiftData

struct QSOEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let qso: QSO?
    
    @State private var callsign = ""
    @State private var datetimeOn = Date()
    @State private var datetimeOff = Date()
    @State private var frequency = ""
    @State private var band = ""
    @State private var mode = "SSB"
    @State private var rstSent = "59"
    @State private var rstRcvd = "59"
    @State private var txPwr = ""
    @State private var qslSent = QSLStatus.no
    @State private var qslRcvd = QSLStatus.no
    @State private var qslSentDate: Date?
    @State private var qslRcvdDate: Date?
    @State private var qslVia = ""
    @State private var country = ""
    @State private var cqZone = ""
    @State private var ituZone = ""
    @State private var gridLocator = ""
    @State private var city = ""
    @State private var province = ""
    @State private var address = ""
    @State private var name = ""
    @State private var comment = ""
    
    @State private var showingCallsignLookup = false
    @State private var duplicateWarning = false
    @State private var selectedRepeaterID: UUID?
    @State private var isFetchingLocation = false

    @StateObject private var locationManager = LocationManager()

    @Query(sort: \Repeater.name) private var repeaters: [Repeater]
    
    private let bands = ["160m", "80m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "2m", "70cm"]
    private let modes = ["SSB", "CW", "FT8", "FT4", "AM", "FM", "RTTY", "PSK31", "JS8"]
    private let qslViaOptions = ["", "Bureau", "Direct", "LoTW", "eQSL"]
    
    var isEditing: Bool { qso != nil }

    var selectedRepeaterName: String {
        guard let id = selectedRepeaterID,
              let rptr = repeaters.first(where: { $0.id == id }) else {
            return ""
        }
        return rptr.name
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Callsign section
                Section("通联信息") {
                    HStack {
                        TextField("呼号", text: $callsign)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                        
                        Button {
                            lookupCallsign()
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                        .disabled(callsign.isEmpty)
                    }
                    
                    DatePicker("开始时间", selection: $datetimeOn)
                    DatePicker("结束时间", selection: $datetimeOff)

                    if !repeaters.isEmpty {
                        Picker("中继台", selection: $selectedRepeaterID) {
                            Text("无（手动输入）").tag(nil as UUID?)
                            ForEach(repeaters) { rptr in
                                Text("\(rptr.name) (\(rptr.callsign))").tag(rptr.id as UUID?)
                            }
                        }
                        .onChange(of: selectedRepeaterID) { _, newID in
                            applyRepeater(newID)
                        }
                    }

                    HStack {
                        Picker("频段", selection: $band) {
                            Text("选择频段").tag("")
                            ForEach(bands, id: \.self) { band in
                                Text(band).tag(band)
                            }
                        }
                        
                        TextField("频率 (MHz)", text: $frequency)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("模式", selection: $mode) {
                        ForEach(modes, id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                }
                
                // Signal reports
                Section("信号报告") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("发送 (RST)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("59", text: $rstSent)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("接收 (RST)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("59", text: $rstRcvd)
                        }
                    }
                    
                    TextField("发射功率 (W)", text: $txPwr)
                        .keyboardType(.decimalPad)
                }
                
                // Station info
                Section("台站信息") {
                    TextField("国家/地区", text: $country)
                    
                    HStack {
                        TextField("CQ分区", text: $cqZone)
                            .keyboardType(.numberPad)
                        TextField("ITU分区", text: $ituZone)
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        TextField("网格定位", text: $gridLocator)
                            .textInputAutocapitalization(.characters)
                        
                        Button {
                            fetchCurrentLocation()
                        } label: {
                            if isFetchingLocation {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "location.fill")
                            }
                        }
                        .disabled(isFetchingLocation)
                    }
                    
                    TextField("城市", text: $city)
                    TextField("省份/州", text: $province)
                    TextField("详细地址", text: $address)
                    
                    TextField("操作员姓名", text: $name)
                }
                
                // QSL status
                Section("QSL卡片") {
                    Picker("发送状态", selection: $qslSent) {
                        ForEach(QSLStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    if qslSent == .yes {
                        DatePicker("发送日期", selection: Binding(
                            get: { qslSentDate ?? Date() },
                            set: { qslSentDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    Picker("接收状态", selection: $qslRcvd) {
                        ForEach(QSLStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    
                    if qslRcvd == .yes {
                        DatePicker("接收日期", selection: Binding(
                            get: { qslRcvdDate ?? Date() },
                            set: { qslRcvdDate = $0 }
                        ), displayedComponents: .date)
                    }
                    
                    Picker("发送方式", selection: $qslVia) {
                        ForEach(qslViaOptions, id: \.self) { via in
                            Text(via.isEmpty ? "未指定" : via).tag(via)
                        }
                    }
                }
                
                // Comment
                Section("备注") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "编辑通联" : "新增通联")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveQSO()
                    }
                    .disabled(callsign.isEmpty)
                }
            }
            .alert("重复通联", isPresented: $duplicateWarning) {
                Button("继续保存", role: .cancel) {
                    saveQSO(force: true)
                }
                Button("返回修改", role: .destructive) { }
            } message: {
                Text("已存在相同呼号、时间、频段和模式的通联记录，是否继续保存？")
            }
            .onAppear {
                loadQSOData()
            }
        }
    }
    
    private func loadQSOData() {
        guard let qso = qso else { return }

        callsign = qso.callsign
        datetimeOn = qso.datetimeOn
        datetimeOff = qso.datetimeOff
        frequency = qso.frequency > 0 ? String(qso.frequency) : ""
        band = qso.band
        mode = qso.mode
        rstSent = qso.rstSent
        rstRcvd = qso.rstRcvd
        txPwr = qso.txPwr > 0 ? String(qso.txPwr) : ""
        qslSent = qso.qslSent
        qslRcvd = qso.qslRcvd
        qslSentDate = qso.qslSentDate
        qslRcvdDate = qso.qslRcvdDate
        qslVia = qso.qslVia
        country = qso.country
        cqZone = qso.cqZone > 0 ? String(qso.cqZone) : ""
        ituZone = qso.ituZone > 0 ? String(qso.ituZone) : ""
        gridLocator = qso.gridLocator
        city = qso.city
        province = qso.province
        address = qso.address
        name = qso.name
        comment = qso.comment

        // Restore repeater selection
        let rptrName = qso.repeaterName
        if !rptrName.isEmpty,
           let rptr = repeaters.first(where: { $0.name == rptrName }) {
            selectedRepeaterID = rptr.id
        }
    }

    private func applyRepeater(_ id: UUID?) {
        guard let id = id,
              let rptr = repeaters.first(where: { $0.id == id }) else {
            return
        }
        // Fill QSO fields from repeater
        frequency = rptr.uplinkFreq > 0 ? String(rptr.uplinkFreq) : ""
        band = rptr.band
        mode = rptr.mode
        // Append repeater info to comment (don't overwrite existing)
        let rptrNote = "中继台: \(rptr.name) (\(rptr.callsign))"
        if comment.isEmpty {
            comment = rptrNote
        } else if !comment.contains(rptrNote) {
            comment = rptrNote + "\n" + comment
        }
    }
    
    private func fetchCurrentLocation() {
        isFetchingLocation = true
        locationManager.getCurrentLocationInfo { [weak self] grid, city, province, address, error in
            DispatchQueue.main.async {
                self?.isFetchingLocation = false
                if let grid = grid {
                    self?.gridLocator = grid
                }
                if let city = city, !city.isEmpty {
                    self?.city = city
                }
                if let province = province, !province.isEmpty {
                    self?.province = province
                }
                if let address = address, !address.isEmpty {
                    self?.address = address
                }
                if let error = error {
                    // Show error message
                    print("位置获取失败: \(error)")
                }
            }
        }
    }
    
    private func lookupCallsign() {
        // TODO: Implement callsign lookup
        showingCallsignLookup = true
    }
    
    private func checkDuplicate() -> Bool {
        let predicate = #Predicate<QSO> { qso in
            qso.callsign == callsign &&
            qso.band == band &&
            qso.mode == mode &&
            !qso.isDeleted
        }
        
        let descriptor = FetchDescriptor<QSO>(predicate: predicate)
        let existing = try? modelContext.fetch(descriptor)
        return existing?.isEmpty == false
    }
    
    private func saveQSO(force: Bool = false) {
        if !force && !isEditing && checkDuplicate() {
            duplicateWarning = true
            return
        }
        
        if let qso = qso {
            // Update existing
            qso.callsign = callsign.uppercased()
            qso.datetimeOn = datetimeOn
            qso.datetimeOff = datetimeOff
            qso.frequency = Double(frequency) ?? 0
            qso.band = band
            qso.mode = mode
            qso.rstSent = rstSent
            qso.rstRcvd = rstRcvd
            qso.txPwr = Double(txPwr) ?? 0
            qso.qslSent = qslSent
            qso.qslRcvd = qslRcvd
            qso.qslSentDate = qslSentDate
            qso.qslRcvdDate = qslRcvdDate
            qso.qslVia = qslVia
            qso.country = country
            qso.cqZone = Int(cqZone) ?? 0
            qso.ituZone = Int(ituZone) ?? 0
            qso.gridLocator = gridLocator.uppercased()
            qso.city = city
            qso.province = province
            qso.address = address
            qso.name = name
            qso.comment = comment
            qso.repeaterName = selectedRepeaterName
            qso.updatedAt = Date()
        } else {
            // Create new
            let newQSO = QSO(
                callsign: callsign.uppercased(),
                datetimeOn: datetimeOn,
                datetimeOff: datetimeOff,
                frequency: Double(frequency) ?? 0,
                band: band,
                mode: mode,
                rstSent: rstSent,
                rstRcvd: rstRcvd,
                txPwr: Double(txPwr) ?? 0,
                qslSent: qslSent,
                qslRcvd: qslRcvd,
                qslSentDate: qslSentDate,
                qslRcvdDate: qslRcvdDate,
                qslVia: qslVia,
                country: country,
                cqZone: Int(cqZone) ?? 0,
                ituZone: Int(ituZone) ?? 0,
                gridLocator: gridLocator.uppercased(),
                city: city,
                province: province,
                address: address,
                name: name,
                comment: comment,
                repeaterName: selectedRepeaterName
            )
            modelContext.insert(newQSO)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    QSOEditView(qso: nil)
}

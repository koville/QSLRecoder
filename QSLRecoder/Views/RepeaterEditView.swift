import SwiftUI

struct RepeaterEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let repeater: Repeater?

    @State private var name = ""
    @State private var callsign = ""
    @State private var uplinkFreqStr = ""
    @State private var downlinkFreqStr = ""
    @State private var band = ""
    @State private var mode = "FM"
    @State private var ctcssTxStr = "88.5"
    @State private var ctcssRxStr = "88.5"
    @State private var location = ""
    @State private var city = ""
    @State private var province = ""
    @State private var latitudeStr = ""
    @State private var longitudeStr = ""
    @State private var comment = ""
    @State private var isFavorite = false

    private let bands = ["160m", "80m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "2m", "70cm", "23cm"]
    private let modes = ["FM", "DMR", "D-STAR", "C4FM", "NXDN", "P25"]
    private let commonCTCSS: [Double] = [67.0, 71.9, 74.4, 77.0, 79.7, 82.5, 85.4, 88.5, 91.5, 94.8,
                                         97.4, 100.0, 103.5, 107.2, 110.9, 114.8, 118.8, 123.0, 127.3,
                                         131.8, 136.5, 141.3, 146.2, 151.4, 156.7, 162.2, 167.9, 173.8,
                                         179.9, 186.2, 192.8, 203.5, 210.7, 218.1, 225.7, 233.6, 241.8,
                                         250.3, 254.1]

    var isEditing: Bool { repeater != nil }

    var offsetFreq: Double {
        let up = Double(uplinkFreqStr) ?? 0
        let down = Double(downlinkFreqStr) ?? 0
        guard up > 0, down > 0 else { return 0 }
        return abs(down - up)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("中继台名称", text: $name)

                    TextField("中继台呼号", text: $callsign)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    Toggle("收藏", isOn: $isFavorite)
                }

                Section("频率") {
                    HStack {
                        Text("下行 (接收)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0.0000", text: $downlinkFreqStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("MHz")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("上行 (发射)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0.0000", text: $uplinkFreqStr)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("MHz")
                            .foregroundColor(.secondary)
                    }

                    if offsetFreq > 0 {
                        LabeledContent("频差", value: String(format: "±%.4f MHz", offsetFreq))
                            .foregroundColor(.secondary)
                    }

                    Picker("频段", selection: $band) {
                        Text("选择频段").tag("")
                        ForEach(bands, id: \.self) { band in
                            Text(band).tag(band)
                        }
                    }

                    Picker("模式", selection: $mode) {
                        ForEach(modes, id: \.self) { mode in
                            Text(mode).tag(mode)
                        }
                    }
                }

                Section("亚音 (CTCSS)") {
                    Picker("发射亚音 (Hz)", selection: $ctcssTxStr) {
                        Text("无").tag("0")
                        ForEach(commonCTCSS, id: \.self) { hz in
                            Text(String(format: "%.1f", hz)).tag(String(format: "%.1f", hz))
                        }
                    }

                    Picker("接收亚音 (Hz)", selection: $ctcssRxStr) {
                        Text("无").tag("0")
                        ForEach(commonCTCSS, id: \.self) { hz in
                            Text(String(format: "%.1f", hz)).tag(String(format: "%.1f", hz))
                        }
                    }
                }

                Section("位置") {
                    TextField("具体地址", text: $location)
                    TextField("城市", text: $city)
                    TextField("省份/地区", text: $province)

                    HStack {
                        TextField("纬度", text: $latitudeStr)
                            .keyboardType(.decimalPad)
                        TextField("经度", text: $longitudeStr)
                            .keyboardType(.decimalPad)
                    }
                }

                Section("备注") {
                    TextEditor(text: $comment)
                        .frame(minHeight: 60)
                }
            }
            .navigationTitle(isEditing ? "编辑中继台" : "新增中继台")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveRepeater() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadRepeaterData() }
        }
    }

    private func loadRepeaterData() {
        guard let rptr = repeater else { return }

        name = rptr.name
        callsign = rptr.callsign
        uplinkFreqStr = rptr.uplinkFreq > 0 ? String(rptr.uplinkFreq) : ""
        downlinkFreqStr = rptr.downlinkFreq > 0 ? String(rptr.downlinkFreq) : ""
        band = rptr.band
        mode = rptr.mode
        ctcssTxStr = rptr.ctcssTx > 0 ? String(format: "%.1f", rptr.ctcssTx) : "0"
        ctcssRxStr = rptr.ctcssRx > 0 ? String(format: "%.1f", rptr.ctcssRx) : "0"
        location = rptr.location
        city = rptr.city
        province = rptr.province
        latitudeStr = rptr.latitude != 0 ? String(rptr.latitude) : ""
        longitudeStr = rptr.longitude != 0 ? String(rptr.longitude) : ""
        comment = rptr.comment
        isFavorite = rptr.isFavorite
    }

    private func saveRepeater() {
        let uplink = Double(uplinkFreqStr) ?? 0
        let downlink = Double(downlinkFreqStr) ?? 0

        if let rptr = repeater {
            rptr.name = name
            rptr.callsign = callsign.uppercased()
            rptr.uplinkFreq = uplink
            rptr.downlinkFreq = downlink
            rptr.offsetFreq = abs(downlink - uplink)
            rptr.band = band
            rptr.mode = mode
            rptr.ctcssTx = Double(ctcssTxStr) ?? 0
            rptr.ctcssRx = Double(ctcssRxStr) ?? 0
            rptr.location = location
            rptr.city = city
            rptr.province = province
            rptr.latitude = Double(latitudeStr) ?? 0
            rptr.longitude = Double(longitudeStr) ?? 0
            rptr.comment = comment
            rptr.isFavorite = isFavorite
            rptr.updatedAt = Date()
        } else {
            let newRptr = Repeater(
                name: name,
                callsign: callsign.uppercased(),
                uplinkFreq: uplink,
                downlinkFreq: downlink,
                offsetFreq: abs(downlink - uplink),
                band: band,
                mode: mode,
                ctcssTx: Double(ctcssTxStr) ?? 88.5,
                ctcssRx: Double(ctcssRxStr) ?? 88.5,
                location: location,
                city: city,
                province: province,
                latitude: Double(latitudeStr) ?? 0,
                longitude: Double(longitudeStr) ?? 0,
                comment: comment,
                isFavorite: isFavorite
            )
            modelContext.insert(newRptr)
        }

        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    RepeaterEditView(repeater: nil)
}
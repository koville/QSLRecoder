import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(filter: #Predicate<QSO> { !$0.isDeleted }) private var allQSOs: [QSO]
    
    @State private var selectedPeriod = Period.all
    @State private var showingDetailedStats = false
    
    enum Period: String, CaseIterable {
        case all = "全部"
        case year = "今年"
        case month = "本月"
        case week = "本周"
    }
    
    var filteredQSOs: [QSO] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedPeriod {
        case .all:
            return allQSOs
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return allQSOs.filter { $0.datetimeOn >= startOfYear }
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return allQSOs.filter { $0.datetimeOn >= startOfMonth }
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return allQSOs.filter { $0.datetimeOn >= startOfWeek }
        }
    }
    
    var statistics: StatisticsData {
        var stats = StatisticsData()
        stats.totalQSOs = filteredQSOs.count
        
        // Group by band
        stats.qsoByBand = Dictionary(grouping: filteredQSOs, by: { $0.band })
            .mapValues { $0.count }
        
        // Group by mode
        stats.qsoByMode = Dictionary(grouping: filteredQSOs, by: { $0.mode })
            .mapValues { $0.count }
        
        // Group by country
        stats.qsoByCountry = Dictionary(grouping: filteredQSOs, by: { $0.country })
            .mapValues { $0.count }
        
        // Group by month
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        stats.qsoByMonth = Dictionary(grouping: filteredQSOs, by: { formatter.string(from: $0.datetimeOn) })
            .mapValues { $0.count }
        
        // QSL stats
        stats.qslSentCount = filteredQSOs.filter { $0.qslSent == .yes }.count
        stats.qslRcvdCount = filteredQSOs.filter { $0.qslRcvd == .yes }.count
        stats.qslConfirmedCount = filteredQSOs.filter { $0.qslSent == .yes && $0.qslRcvd == .yes }.count
        
        // DXCC (unique countries)
        stats.dxccCount = Set(filteredQSOs.map { $0.country }).filter { !$0.isEmpty }.count
        
        // WAZ (unique CQ zones)
        stats.wazCount = Set(filteredQSOs.map { $0.cqZone }).filter { $0 > 0 }.count
        
        return stats
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Period picker
                Picker("时间段", selection: $selectedPeriod) {
                    ForEach(Period.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Summary cards
                summaryCards
                
                // Charts
                if !filteredQSOs.isEmpty {
                    bandChart
                    modeChart
                    countryChart
                    qslStatsCard
                } else {
                    ContentUnavailableView {
                        Label("暂无通联记录", systemImage: "chart.bar")
                    } description: {
                        Text("添加通联记录后，这里将显示统计分析")
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("统计分析")
    }
    
    private var summaryCards: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(title: "总通联数", value: "\(statistics.totalQSOs)", icon: "radio", color: .blue)
            StatCard(title: "DXCC", value: "\(statistics.dxccCount)", icon: "globe", color: .green)
            StatCard(title: "WAZ", value: "\(statistics.wazCount)", icon: "map", color: .orange)
            StatCard(title: "确认率", value: String(format: "%.1f%%", confirmationRate), icon: "checkmark.seal", color: .purple)
        }
        .padding(.horizontal)
    }
    
    private var confirmationRate: Double {
        guard statistics.totalQSOs > 0 else { return 0 }
        return Double(statistics.qslConfirmedCount) / Double(statistics.totalQSOs) * 100
    }
    
    private var bandChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("频段分布")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(statistics.qsoByBand.sorted(by: { $0.key < $1.key }), id: \.key) { band, count in
                    BarMark(
                        x: .value("频段", band),
                        y: .value("通联数", count)
                    )
                    .foregroundStyle(by: .value("频段", band))
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }
    
    private var modeChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("模式分布")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(statistics.qsoByMode.sorted(by: { $0.value > $1.value }), id: \.key) { mode, count in
                    SectorMark(
                        angle: .value("通联数", count),
                        innerRadius: .ratio(0.5),
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("模式", mode))
                    .annotation(position: .overlay) {
                        Text("\(mode)\n\(count)")
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(height: 250)
            .padding(.horizontal)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }
    
    private var countryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("热门国家/地区")
                    .font(.headline)
                
                Spacer()
                
                Button("查看全部") {
                    showingDetailedStats = true
                }
                .font(.caption)
            }
            .padding(.horizontal)
            
            let topCountries = statistics.qsoByCountry.sorted(by: { $0.value > $1.value }).prefix(10)
            
            ForEach(Array(topCountries), id: \.key) { country, count in
                HStack {
                    Text(country.isEmpty ? "未知" : country)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Text("\(count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }
    
    private var qslStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QSL卡片统计")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                QSLStatRow(label: "已发送", count: statistics.qslSentCount, total: statistics.totalQSOs, color: .blue)
                QSLStatRow(label: "已收到", count: statistics.qslRcvdCount, total: statistics.totalQSOs, color: .green)
                QSLStatRow(label: "已确认", count: statistics.qslConfirmedCount, total: statistics.totalQSOs, color: .purple)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title2)
                
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8)
    }
}

struct QSLStatRow: View {
    let label: String
    let count: Int
    let total: Int
    let color: Color
    
    var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                
                Spacer()
                
                Text("\(count) (\(String(format: "%.1f%%", percentage)))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: percentage, total: 100)
                .tint(color)
        }
    }
}

#Preview {
    NavigationStack {
        StatisticsView()
    }
}

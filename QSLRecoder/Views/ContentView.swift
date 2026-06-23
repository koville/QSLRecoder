import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .log
    
    enum Tab: String, CaseIterable {
        case log = "通联日志"
        case qsl = "QSL卡片"
        case stats = "统计分析"
        case settings = "设置"
        
        var icon: String {
            switch self {
            case .log: return "book.fill"
            case .qsl: return "envelope.fill"
            case .stats: return "chart.bar.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    tabContent(for: tab)
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
    }
    
    @ViewBuilder
    private func tabContent(for tab: Tab) -> some View {
        switch tab {
        case .log:
            QSOListView()
        case .qsl:
            QSLManagementView()
        case .stats:
            StatisticsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
}

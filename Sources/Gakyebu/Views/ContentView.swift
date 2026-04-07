import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable {
    case transactions = "거래 내역"
    case assets       = "자산"
    case stats        = "통계"
    case budget       = "예산 설정"
    case categories   = "카테고리 관리"
    case settings     = "설정"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .transactions: return "list.bullet.rectangle.portrait"
        case .assets:       return "banknote"
        case .stats:        return "chart.bar.xaxis"
        case .budget:       return "target"
        case .categories:   return "tag"
        case .settings:     return "gearshape"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var selection: SidebarItem? = .transactions

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            Group {
                switch selection ?? .transactions {
                case .transactions: TransactionListView()
                case .assets:       AssetView()
                case .stats:        StatsView()
                case .budget:       BudgetView()
                case .categories:   CategoryManagementView()
                case .settings:     SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DS.bg)
        }
        .overlay {
            if store.isLoading {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("불러오는 중…").font(.callout).foregroundStyle(DS.textSecondary)
                    }
                    .padding(24)
                    .cardStyle()
                }
            }
        }
        .alert("오류", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.errorMessage = nil } }
        )) {
            Button("확인") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}

// MARK: - Sidebar

struct SidebarView: View {
    @Binding var selection: SidebarItem?

    var body: some View {
        VStack(spacing: 0) {
            // App header
            HStack(spacing: 10) {
                Image(systemName: "wonsign.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(DS.accent)
                Text("가계부")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()
                .padding(.bottom, 8)

            ForEach(SidebarItem.allCases) { item in
                SidebarRow(item: item, isSelected: selection == item)
                    .onTapGesture { selection = item }
            }

            Spacer()
        }
        .background(DS.sidebar)
    }
}

struct SidebarRow: View {
    let item: SidebarItem
    let isSelected: Bool
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.icon)
                .font(.system(size: 15, weight: .medium))
                .frame(width: 22)
                .foregroundStyle(isSelected ? DS.accent : DS.textSecondary)

            Text(item.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? DS.textPrimary : DS.textSecondary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? DS.accent.opacity(0.1)
                      : hovering ? DS.textPrimary.opacity(0.04) : .clear)
        )
        .padding(.horizontal, 8)
        .onHover { hovering = $0 }
    }
}

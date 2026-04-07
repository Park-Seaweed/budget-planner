import SwiftUI

struct AssetView: View {
    @EnvironmentObject var store: AppStore
    @State private var showAdd = false
    @State private var editingAsset: Asset? = nil

    private var totalAsset: Int { store.assets.reduce(0) { $0 + $1.amount } }
    private var totalIncome: Int { store.transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount } }
    private var totalExpense: Int { store.transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount } }
    private var netBalance: Int { totalAsset + totalIncome - totalExpense }

    private var groupedAssets: [(AssetType, [Asset])] {
        let dict = Dictionary(grouping: store.assets) { $0.type }
        return AssetType.allCases.compactMap { type in
            guard let assets = dict[type], !assets.isEmpty else { return nil }
            return (type, assets)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── 요약 헤더 ──────────────────────────────────────────
            VStack(spacing: 12) {
                // 잔액 메인 카드
                VStack(spacing: 6) {
                    Text("순 자산")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                    Text(netBalance.wonFormatted)
                        .font(.system(size: 28, weight: .bold).monospacedDigit())
                        .foregroundStyle(netBalance >= 0 ? DS.positive : DS.expense)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .cardStyle()

                // 세부 카드
                HStack(spacing: 12) {
                    AssetSummaryCard(label: "등록 자산", amount: totalAsset, color: DS.accent)
                    AssetSummaryCard(label: "총 수입", amount: totalIncome, color: DS.income)
                    AssetSummaryCard(label: "총 지출", amount: totalExpense, color: DS.expense)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
            .background(DS.bg)

            Divider().opacity(0.4)

            // ── 자산 목록 ───────────────────────────────────────────
            if store.assets.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "banknote")
                        .font(.system(size: 36))
                        .foregroundStyle(DS.textSecondary.opacity(0.4))
                    Text("등록된 자산이 없습니다")
                        .foregroundStyle(DS.textSecondary)
                    Button("자산 추가") { showAdd = true }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(DS.accent, in: Capsule())
                        .buttonStyle(.plain)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12, pinnedViews: .sectionHeaders) {
                        ForEach(groupedAssets, id: \.0) { (type, assets) in
                            Section {
                                VStack(spacing: 0) {
                                    ForEach(Array(assets.enumerated()), id: \.element.id) { idx, asset in
                                        AssetRow(
                                            asset: asset,
                                            isLast: idx == assets.count - 1,
                                            onEdit: { editingAsset = asset },
                                            onDelete: { store.deleteAsset(asset) }
                                        )
                                    }
                                }
                                .cardStyle()
                            } header: {
                                HStack {
                                    Text(type.emoji + " " + type.label)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(DS.textSecondary)
                                    Spacer()
                                    let subtotal = assets.reduce(0) { $0 + $1.amount }
                                    Text(subtotal.wonFormatted)
                                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                                        .foregroundStyle(DS.textPrimary)
                                }
                                .padding(.horizontal, 4)
                                .padding(.vertical, 8)
                                .background(DS.bg)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 80)
                }
                .background(DS.bg)
            }
        }
        .background(DS.bg)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAdd = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text("자산 추가")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(DS.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showAdd) {
            AssetFormView().environmentObject(store)
        }
        .sheet(item: $editingAsset) { asset in
            AssetFormView(editing: asset).environmentObject(store)
        }
    }
}

// MARK: - Asset Row

struct AssetRow: View {
    let asset: Asset
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(DS.accent.opacity(0.1))
                    .frame(width: 40, height: 40)
                Text(asset.type.emoji)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                if !asset.memo.isEmpty {
                    Text(asset.memo)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.textSecondary)
                }
            }

            Spacer()

            Text(asset.amount.wonFormatted)
                .font(.system(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(DS.textPrimary)

            if hovering {
                HStack(spacing: 4) {
                    Button { onEdit() } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.textSecondary)
                            .frame(width: 26, height: 26)
                            .background(DS.bg, in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.expense)
                            .frame(width: 26, height: 26)
                            .background(DS.expense.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(hovering ? DS.bg.opacity(0.6) : DS.card)
        .overlay(alignment: .bottom) {
            if !isLast { Divider().padding(.leading, 70).opacity(0.5) }
        }
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
        .onTapGesture(count: 2) { onEdit() }
    }
}

// MARK: - Asset Form

struct AssetFormView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss

    var editing: Asset? = nil

    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var type: AssetType = .bank
    @State private var memo: String = ""

    private var isValid: Bool { !name.isEmpty && (Int(amountText.replacingOccurrences(of: ",", with: "")) ?? 0) > 0 }

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text(editing == nil ? "자산 추가" : "자산 수정")
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(DS.textSecondary.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            Divider().opacity(0.4)

            ScrollView {
                VStack(spacing: 16) {
                    // 자산 유형
                    FormSection(title: "유형") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(AssetType.allCases, id: \.self) { t in
                                let isSelected = type == t
                                Button { type = t } label: {
                                    VStack(spacing: 4) {
                                        Text(t.emoji).font(.system(size: 20))
                                        Text(t.label)
                                            .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                                            .foregroundStyle(isSelected ? DS.accent : DS.textSecondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(isSelected ? DS.accent.opacity(0.1) : DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                                    .overlay(RoundedRectangle(cornerRadius: DS.radiusSM).stroke(isSelected ? DS.accent.opacity(0.4) : Color.clear, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 자산명
                    FormSection(title: "자산명") {
                        PlaceholderTextField(placeholder: "예) 국민은행 주계좌", text: $name)
                            .padding(12)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }

                    // 금액
                    FormSection(title: "금액") {
                        HStack {
                            PlaceholderTextField(placeholder: "0", text: $amountText)
                                .onChange(of: amountText) { formatAmount($0) }
                            Text("원").foregroundStyle(DS.textSecondary)
                        }
                        .padding(12)
                        .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }

                    // 메모
                    FormSection(title: "메모 (선택)") {
                        PlaceholderTextField(placeholder: "간단한 설명", text: $memo)
                            .padding(12)
                            .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                    }
                }
                .padding(24)
            }

            Divider().opacity(0.4)

            // 저장 버튼
            Button {
                let amount = Int(amountText.replacingOccurrences(of: ",", with: "")) ?? 0
                if var a = editing {
                    a.name = name; a.amount = amount; a.type = type; a.memo = memo
                    store.updateAsset(a)
                } else {
                    store.addAsset(Asset(name: name, amount: amount, type: type, memo: memo))
                }
                dismiss()
            } label: {
                Text(editing == nil ? "추가" : "저장")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(isValid ? DS.accent : DS.textSecondary.opacity(0.3), in: RoundedRectangle(cornerRadius: DS.radiusSM))
            }
            .buttonStyle(.plain)
            .disabled(!isValid)
            .padding(24)
        }
        .frame(width: 400)
        .background(DS.card)
        .onAppear {
            if let a = editing {
                name = a.name
                amountText = a.amount.formatted()
                type = a.type
                memo = a.memo
            }
        }
    }

    private func formatAmount(_ raw: String) {
        let digits = raw.replacingOccurrences(of: ",", with: "").filter { $0.isNumber }
        if let n = Int(digits) {
            amountText = n.formatted()
        } else {
            amountText = digits
        }
    }
}

// MARK: - Helpers

struct AssetSummaryCard: View {
    let label: String
    let amount: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(DS.textSecondary)
            Text(amount.wonFormatted)
                .font(.system(size: 14, weight: .bold).monospacedDigit())
                .foregroundStyle(color)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .cardStyle()
    }
}

struct FormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(DS.textSecondary)
            content()
        }
    }
}

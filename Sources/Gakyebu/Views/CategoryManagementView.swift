import SwiftUI

struct CategoryManagementView: View {
    @EnvironmentObject var store: AppStore
    @ObservedObject var categories = CategoryStore.shared
    @State private var showAdd: TransactionType? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CategorySection(
                    title: "지출 카테고리",
                    icon: "arrow.up.circle.fill",
                    color: DS.expense,
                    items: categories.expenseCategories,
                    type: .expense,
                    onAdd: { showAdd = .expense },
                    onDelete: { categories.remove($0, type: .expense) },
                    onRename: { item, name, emoji in
                        store.renameCategory(from: item.name, to: name)
                        categories.rename(item, newName: name, newEmoji: emoji, type: .expense)
                    }
                )

                CategorySection(
                    title: "수입 카테고리",
                    icon: "arrow.down.circle.fill",
                    color: DS.income,
                    items: categories.incomeCategories,
                    type: .income,
                    onAdd: { showAdd = .income },
                    onDelete: { categories.remove($0, type: .income) },
                    onRename: { item, name, emoji in
                        store.renameCategory(from: item.name, to: name)
                        categories.rename(item, newName: name, newEmoji: emoji, type: .income)
                    }
                )

                Spacer(minLength: 32)
            }
            .padding(20)
        }
        .background(DS.bg)
        .sheet(item: $showAdd) { type in
            AddCategoryView(type: type)
        }
    }
}

// MARK: - Section

struct CategorySection: View {
    let title: String
    let icon: String
    let color: Color
    let items: [CategoryItem]
    let type: TransactionType
    let onAdd: () -> Void
    let onDelete: (CategoryItem) -> Void
    let onRename: (CategoryItem, String, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Button {
                    onAdd()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("추가")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(DS.accent.opacity(0.1), in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    CategoryManageRow(
                        item: item,
                        isLast: idx == items.count - 1,
                        onDelete: { onDelete(item) },
                        onRename: { name, emoji in onRename(item, name, emoji) }
                    )
                }
            }
            .cardStyle()
        }
    }
}

// MARK: - Row

struct CategoryManageRow: View {
    let item: CategoryItem
    let isLast: Bool
    let onDelete: () -> Void
    let onRename: (String, String) -> Void

    @State private var hovering = false
    @State private var isEditing = false
    @State private var editName: String = ""
    @State private var editEmoji: String = ""
    @State private var showDeleteConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                editingRow
            } else {
                normalRow
            }
            if !isLast {
                Divider().padding(.leading, 68).opacity(0.5)
            }
        }
    }

    // MARK: Normal

    private var normalRow: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(item.type == .expense
                          ? DS.expense.opacity(0.1)
                          : DS.income.opacity(0.1))
                    .frame(width: 38, height: 38)
                Text(item.emoji)
                    .font(.system(size: 18))
            }

            Text(item.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.textPrimary)

            Spacer()

            if hovering {
                HStack(spacing: 6) {
                    Button {
                        editName  = item.name
                        editEmoji = item.emoji
                        withAnimation(.easeInOut(duration: 0.15)) { isEditing = true }
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.accent)
                            .frame(width: 28, height: 28)
                            .background(DS.accent.opacity(0.1), in: Circle())
                    }
                    .buttonStyle(.plain)

                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.expense)
                            .frame(width: 28, height: 28)
                            .background(DS.expense.opacity(0.08), in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(hovering ? DS.bg.opacity(0.5) : DS.card)
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hovering = h } }
        .confirmationDialog(
            "\(item.name) 카테고리를 삭제할까요?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("삭제", role: .destructive) { onDelete() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("이미 기록된 거래 내역은 유지됩니다.")
        }
    }

    // MARK: Editing

    private var editingRow: some View {
        HStack(spacing: 12) {
            // Emoji picker
            ZStack {
                Circle()
                    .fill(item.type == .expense
                          ? DS.expense.opacity(0.1)
                          : DS.income.opacity(0.1))
                    .frame(width: 38, height: 38)
                TextField("", text: $editEmoji)
                    .font(.system(size: 18))
                    .multilineTextAlignment(.center)
                    .textFieldStyle(.plain)
                    .frame(width: 38, height: 38)
                    .onChange(of: editEmoji) { _, new in
                        if new.count > 1 { editEmoji = String(new.prefix(1)) }
                    }
            }

            // Name input
            TextField("카테고리 이름", text: $editName)
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(DS.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DS.bg, in: RoundedRectangle(cornerRadius: DS.radiusSM))
                .frame(maxWidth: .infinity)

            // Confirm / Cancel
            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { isEditing = false }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(DS.bg, in: Circle())
                }
                .buttonStyle(.plain)

                Button {
                    guard !editName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                    onRename(editName, editEmoji)
                    withAnimation(.easeInOut(duration: 0.15)) { isEditing = false }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(DS.accent, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(editName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(DS.accent.opacity(0.04))
    }
}

// MARK: - TransactionType Identifiable (for sheet)

extension TransactionType: Identifiable {
    public var id: String { rawValue }
}

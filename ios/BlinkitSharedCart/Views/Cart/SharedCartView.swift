import SwiftUI

struct SharedCartView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel = CartViewModel()
    let cart: Cart

    private var items: [SharedCartItem] { cart.items }

    private var visibleItems: [SharedCartItem] {
        viewModel.sortedItems(cart: cart, appState: appState)
    }

    private var subtotal: Int {
        items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
    }

    private var savings: Int {
        items.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + (product.mrp - product.price) * item.qty
        }
    }

    private var itemCount: Int { items.reduce(0) { $0 + $1.qty } }

    private var duplicateProductIds: [String] {
        viewModel.duplicateProductIds(cart: cart)
    }

    private var duplicateItemsCount: Int {
        duplicateProductIds.count
    }

    var body: some View {
        Group {
            if items.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        groupHeader
                        if savings > 0 { savingsBanner }
                        metaRow
                        
                        // Duplicates warnings with Liquid Glass
                        if duplicateItemsCount > 0 {
                            duplicatesWarningBanner
                        }
                        
                        itemsHeader
                        
                        // Grouped members sections
                        VStack(spacing: 12) {
                            ForEach(appState.members) { member in
                                memberGroupSection(member: member)
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        FreeDeliveryNudge(subtotal: subtotal)
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 100)
                }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if !items.isEmpty {
                VStack(spacing: 0) {
                    // Navigation to Address Selection
                    NavigationLink {
                        AddressView(cartId: cart.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("₹\(CartMath.estTotal(subtotal: subtotal))")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                if savings > 0 {
                                    Text("Saved ₹\(savings)")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(Theme.offerText)
                                }
                            }
                            Spacer()
                            HStack(spacing: 4) {
                                Text("Choose address")
                                    .font(.system(size: 15, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Theme.primary, Theme.primary.opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: Theme.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                    .buttonStyle(.plain)
                    
                    // Split Payment row
                    Button {
                        viewModel.showingSplitSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textPrimary)
                            Text("Split payment — Pay together or split")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                    }
                    .buttonStyle(.plain)
                }
                .background(.ultraThinMaterial)
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
            }
        }
        .onAppear {
            // Expand all members by default
            for m in appState.members {
                viewModel.expandedUsers.insert(m.id)
            }
        }
        .sheet(isPresented: $viewModel.showingSortSheet) {
            SortFilterSheet(sortOption: $viewModel.sortOption, filterMemberId: $viewModel.filterMemberId)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingSplitSheet) {
            SplitPaymentSheet(cart: cart)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingMyCodeSheet) {
            MyCodeSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $viewModel.showingAddProductSheet) {
            addProductSheetView
        }
        .sheet(isPresented: $viewModel.showingDuplicatesSheet) {
            duplicatesReviewSheetView
        }
    }

    private var groupHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(cart.name) cart")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                HStack(spacing: -6) {
                    ForEach(appState.members) { member in
                        avatar(name: member.name, hex: member.colorHex, size: 24)
                            .overlay(Circle().stroke(Theme.card, lineWidth: 1.5))
                    }
                }
                Text("\(appState.members.count) members active")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            
            // Invite button
            Button {
                viewModel.showingMyCodeSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Share")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.primary.opacity(0.1))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Theme.primary, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .liquidGlassBackground()
        .padding(.horizontal, 16)
    }

    private var savingsBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "tag.fill")
                .font(.system(size: 14))
                .foregroundStyle(Theme.offerText)
            Text("You are saving ₹\(savings) on this order")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.offerText)
            Spacer()
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(hex: "FEF3C7").opacity(0.9), Color(hex: "FFFBEB").opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "FEF3C7"), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var metaRow: some View {
        HStack {
            Text("\(itemCount) items · Est. total ₹\(CartMath.estTotal(subtotal: subtotal))")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.textSecondary)
            Spacer()
            Text("Delivery in 25 mins")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Theme.primary)
        }
        .padding(.horizontal, 16)
    }

    private var duplicatesWarningBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "D97706"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Duplicate items detected (\(duplicateItemsCount))")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("We found similar items added by different members.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textSecondary)
            }
            
            Spacer()
            
            Button {
                viewModel.showingDuplicatesSheet = true
            } label: {
                Text("Review")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.offerText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.offerText, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            LinearGradient(
                colors: [Color(hex: "FFFBEB"), Color(hex: "FFFBEB").opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FEF3C7"), lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private var itemsHeader: some View {
        HStack {
            Text("Items in cart")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let filterMemberId = viewModel.filterMemberId {
                filterChip(for: filterMemberId)
            }
            Button { viewModel.showingSortSheet = true } label: {
                Label("Sort & Filter", systemImage: "arrow.up.arrow.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
    }

    private func filterChip(for memberId: String) -> some View {
        let name = memberId == appState.user?.id ? "You" : (appState.memberFor(memberId)?.name ?? "")
        return Button {
            viewModel.filterMemberId = nil
        } label: {
            HStack(spacing: 4) {
                Text(name).font(.system(size: 11, weight: .semibold))
                Image(systemName: "xmark").font(.system(size: 9))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Theme.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func memberGroupSection(member: User) -> some View {
        let isYou = member.id == appState.user?.id
        let memberItems = visibleItems.filter { $0.addedById == member.id }
        let isExpanded = viewModel.isExpanded(memberId: member.id)
        
        let qtyCount = memberItems.reduce(0) { $0 + $1.qty }
        let totalVal = memberItems.reduce(0) { total, item in
            guard let product = appState.productFor(item.productId) else { return total }
            return total + product.price * item.qty
        }
        
        let duplicatesInGroup = memberItems.filter { duplicateProductIds.contains($0.productId) }
        
        return VStack(spacing: 0) {
            // Group Header Button with Liquid Glass styling
            Button {
                withAnimation {
                    viewModel.toggleUserExpansion(memberId: member.id)
                }
            } label: {
                HStack(spacing: 10) {
                    avatar(name: member.name, hex: member.colorHex, size: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(isYou ? "You (\(member.name))" : member.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        
                        HStack(spacing: 8) {
                            Text("\(qtyCount) items · ₹\(totalVal)")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.textSecondary)
                            
                            if !duplicatesInGroup.isEmpty {
                                Text("\(duplicatesInGroup.count) duplicate item")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(Color(hex: "C2410C"))
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Color(hex: "FEF3C7"))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(14)
                .background(Color.white.opacity(0.35))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider().background(Theme.border.opacity(0.5))
                    
                    if memberItems.isEmpty {
                        Text("No items added yet.")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.vertical, 16)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(Array(memberItems.enumerated()), id: \.element.id) { idx, item in
                                if let product = appState.productFor(item.productId) {
                                    CartItemRow(cart: cart, item: item, product: product)
                                    if idx < memberItems.count - 1 {
                                        Divider().background(Theme.border.opacity(0.5))
                                    }
                                }
                            }
                        }
                    }
                    
                    // Add items local button
                    Button {
                        viewModel.showingAddProductSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                            Text("Add item")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(Theme.primary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Theme.primary.opacity(0.04))
                        .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border.opacity(0.5)), alignment: .top)
                    }
                    .buttonStyle(.plain)
                }
                .background(Color.white.opacity(0.15))
            }
        }
        .liquidGlassBackground()
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("⚡")
                .font(.system(size: 56))
            Text("Nothing in Shared Cart yet")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Invite family or friends! Everything you add shows up here instantly.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 48)
            
            Button {
                viewModel.showingMyCodeSheet = true
            } label: {
                Text("Invite friends")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Theme.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            Spacer()
        }
    }

    // MARK: - Sub Sheets

    private var addProductSheetView: some View {
        VStack(spacing: 16) {
            Text("Add Item to Shared Cart")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 20)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(appState.products) { product in
                        HStack(spacing: 12) {
                            Text(product.emoji)
                                .font(.system(size: 24))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(product.name)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.textPrimary)
                                Text("\(product.unit) · ₹\(product.price)")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                appState.addToCart(cartId: cart.id, productId: product.id)
                                appState.showToast("Added \(product.name) to Home Cart!")
                            } label: {
                                Text("ADD")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(Theme.primary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .cardBackground()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Theme.background)
    }

    private var duplicatesReviewSheetView: some View {
        VStack(spacing: 16) {
            Text("Review Duplicate Items")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.textPrimary)
                .padding(.top, 20)
            
            Text("The following items have been added by multiple shoppers in your Home Cart. You can adjust quantities below.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(duplicateProductIds, id: \.self) { pid in
                        if let product = appState.productFor(pid) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(product.emoji).font(.system(size: 24))
                                    Text(product.name)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                }
                                
                                ForEach(appState.members) { member in
                                    let memberItem = items.first { $0.productId == pid && $0.addedById == member.id }
                                    if let item = memberItem {
                                        HStack {
                                            avatar(name: member.name, hex: member.colorHex, size: 20)
                                            Text(member.name)
                                                .font(.system(size: 12))
                                                .foregroundStyle(Theme.textSecondary)
                                            Spacer()
                                            
                                            QtyStepper(qty: item.qty) { newQty in
                                                appState.setQty(cartId: cart.id, productId: pid, qty: newQty)
                                            }
                                        }
                                        .padding(.horizontal, 6)
                                    }
                                }
                            }
                            .padding(12)
                            .cardBackground()
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Theme.background)
    }
}

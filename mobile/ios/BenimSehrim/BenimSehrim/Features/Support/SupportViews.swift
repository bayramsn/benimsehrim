import SwiftUI

// MARK: - Support View (Destek Sayfası)
struct SupportView: View {
    @StateObject private var supportManager = SupportManager.shared
    @State private var selectedTab = 0
    @State private var showCreateTicket = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            Picker("", selection: $selectedTab) {
                Text("Talepler").tag(0)
                Text("SSS").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if selectedTab == 0 {
                // Tickets List
                if supportManager.tickets.isEmpty {
                    EmptyTicketsView()
                } else {
                    TicketListView(tickets: supportManager.tickets)
                }
            } else {
                // FAQ
                FAQListView(items: supportManager.faqItems)
            }
        }
        .navigationTitle("Destek")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showCreateTicket = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.primaryGreen)
                }
            }
        }
        .sheet(isPresented: $showCreateTicket) {
            CreateTicketView()
        }
    }
}

struct EmptyTicketsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "ticket")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Henüz destek talebiniz yok")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Bir sorun mu yaşıyorsunuz?\nYeni talep oluşturun.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}

struct TicketListView: View {
    let tickets: [SupportTicket]
    
    var body: some View {
        List {
            Section("Açık Talepler") {
                ForEach(tickets.filter { $0.status != .resolved && $0.status != .closed }) { ticket in
                    NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                        TicketRowView(ticket: ticket)
                    }
                }
            }
            
            Section("Kapalı Talepler") {
                ForEach(tickets.filter { $0.status == .resolved || $0.status == .closed }) { ticket in
                    NavigationLink(destination: TicketDetailView(ticket: ticket)) {
                        TicketRowView(ticket: ticket)
                    }
                }
            }
        }
    }
}

struct TicketRowView: View {
    let ticket: SupportTicket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: ticket.type.icon)
                    .foregroundColor(Color(hex: ticket.status.color))
                
                Text(ticket.ticketNo)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(ticket.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: ticket.status.color).opacity(0.2))
                    .foregroundColor(Color(hex: ticket.status.color))
                    .cornerRadius(4)
            }
            
            Text(ticket.subject)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(timeAgo(from: ticket.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct TicketDetailView: View {
    let ticket: SupportTicket
    @State private var newMessage = ""
    @ObservedObject var supportManager = SupportManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Ticket Info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(ticket.ticketNo)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(ticket.status.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: ticket.status.color).opacity(0.2))
                        .foregroundColor(Color(hex: ticket.status.color))
                        .cornerRadius(4)
                }
                
                Text(ticket.subject)
                    .font(.headline)
                
                Text(ticket.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            
            // Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(ticket.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            // Input
            if ticket.status != .resolved && ticket.status != .closed {
                HStack(spacing: 12) {
                    TextField("Mesaj yazın...", text: $newMessage)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(10)
                            .background(Color.primaryGreen)
                            .clipShape(Circle())
                    }
                    .disabled(newMessage.isEmpty)
                }
                .padding()
            }
        }
        .navigationTitle("Talep Detayı")
    }
    
    private func sendMessage() {
        guard !newMessage.isEmpty else { return }
        supportManager.addMessage(ticketId: ticket.id, content: newMessage)
        newMessage = ""
    }
}

struct MessageBubble: View {
    let message: TicketMessage
    
    var body: some View {
        HStack {
            if !message.isFromSupport {
                Spacer()
            }
            
            VStack(alignment: message.isFromSupport ? .leading : .trailing, spacing: 4) {
                Text(message.senderName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(message.content)
                    .padding(12)
                    .background(message.isFromSupport ? Color(.systemGray5) : Color.primaryGreen)
                    .foregroundColor(message.isFromSupport ? .primary : .white)
                    .cornerRadius(16)
                
                Text(formatTime(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if message.isFromSupport {
                Spacer()
            }
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

struct CreateTicketView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var supportManager = SupportManager.shared
    
    @State private var selectedType: TicketType = .other
    @State private var subject = ""
    @State private var description = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sorun Türü") {
                    Picker("Tür", selection: $selectedType) {
                        ForEach(TicketType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.displayName)
                            }
                            .tag(type)
                        }
                    }
                }
                
                Section("Detaylar") {
                    TextField("Konu", text: $subject)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button(action: submitTicket) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Gönder")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(subject.isEmpty || description.isEmpty || isSubmitting)
                }
            }
            .navigationTitle("Yeni Talep")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") { dismiss() }
                }
            }
        }
    }
    
    private func submitTicket() {
        isSubmitting = true
        
        _ = supportManager.createTicket(
            type: selectedType,
            subject: subject,
            description: description
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            dismiss()
        }
    }
}

struct FAQListView: View {
    let items: [FAQItem]
    @State private var expandedId: String?
    
    var groupedItems: [String: [FAQItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
    
    var body: some View {
        List {
            ForEach(Array(groupedItems.keys.sorted()), id: \.self) { category in
                Section(category) {
                    ForEach(groupedItems[category] ?? []) { item in
                        FAQItemView(item: item, isExpanded: expandedId == item.id) {
                            withAnimation {
                                expandedId = expandedId == item.id ? nil : item.id
                            }
                        }
                    }
                }
            }
        }
    }
}

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onTap) {
                HStack {
                    Text(item.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Rating View
struct RatingView: View {
    let type: RatingType
    let targetId: String
    let targetName: String
    let targetImage: String?
    let orderId: String?
    let rideId: String?
    let onComplete: () -> Void
    
    @State private var rating: Int = 0
    @State private var comment: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isSubmitting = false
    @Environment(\.dismiss) var dismiss
    @ObservedObject var ratingManager = RatingManager.shared
    
    var availableTags: [String] {
        RatingTags.tagsFor(rating: rating)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Target Info
                    VStack(spacing: 12) {
                        if let image = targetImage {
                            AsyncImage(url: URL(string: image)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Circle().fill(Color.gray.opacity(0.2))
                            }
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.primaryGreen.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(targetName.prefix(1)))
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primaryGreen)
                                )
                        }
                        
                        Text(targetName)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(type.displayName)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Star Rating
                    VStack(spacing: 8) {
                        Text("Nasıl buldunuz?")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { rating = star }) {
                                    Image(systemName: star <= rating ? "star.fill" : "star")
                                        .font(.title)
                                        .foregroundColor(star <= rating ? .yellow : .gray)
                                }
                            }
                        }
                        
                        if rating > 0 {
                            Text(ratingText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    
                    // Tags
                    if rating > 0 {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Ne düşündünüz?")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(availableTags, id: \.self) { tag in
                                    TagButton(
                                        tag: tag,
                                        isSelected: selectedTags.contains(tag),
                                        action: {
                                            if selectedTags.contains(tag) {
                                                selectedTags.remove(tag)
                                            } else {
                                                selectedTags.insert(tag)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // Comment
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Yorum (isteğe bağlı)")
                            .font(.headline)
                        
                        TextEditor(text: $comment)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Submit Button
                    Button(action: submitRating) {
                        if isSubmitting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            Text("Gönder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                    }
                    .background(rating > 0 ? Color.primaryGreen : Color.gray)
                    .cornerRadius(12)
                    .disabled(rating == 0 || isSubmitting)
                    .padding()
                }
            }
            .navigationTitle("Değerlendir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Atla") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var ratingText: String {
        switch rating {
        case 1: return "Çok Kötü 😞"
        case 2: return "Kötü 😕"
        case 3: return "Orta 😐"
        case 4: return "İyi 🙂"
        case 5: return "Harika 🤩"
        default: return ""
        }
    }
    
    private func submitRating() {
        isSubmitting = true
        
        _ = ratingManager.submitRating(
            type: type,
            targetId: targetId,
            targetName: targetName,
            orderId: orderId,
            rideId: rideId,
            rating: rating,
            comment: comment.isEmpty ? nil : comment,
            tags: Array(selectedTags)
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSubmitting = false
            onComplete()
            dismiss()
        }
    }
}

struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryGreen : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + lineHeight
        }
    }
}

// MARK: - Search View
struct SearchView: View {
    @State private var searchText = ""
    @State private var searchResults: [Store] = []
    @State private var recentSearches: [String] = []
    @State private var isSearching = false
    
    private let recentKey = "recent_searches"
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Mağaza, ürün ara...", text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { performSearch() }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()
            
            if searchText.isEmpty {
                // Recent Searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Son Aramalar")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Temizle") {
                                recentSearches.removeAll()
                                saveRecentSearches()
                            }
                            .font(.subheadline)
                            .foregroundColor(.red)
                        }
                        
                        ForEach(recentSearches, id: \.self) { search in
                            Button(action: {
                                searchText = search
                                performSearch()
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text(search)
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
            } else {
                // Search Results
                if isSearching {
                    ProgressView()
                        .padding()
                } else if searchResults.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        Text("Sonuç bulunamadı")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(searchResults) { store in
                        NavigationLink(destination: StoreDetailView(storeId: store.id)) {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(Color.primaryGreen.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(store.name.prefix(1)))
                                            .fontWeight(.bold)
                                            .foregroundColor(.primaryGreen)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(store.name)
                                        .font(.headline)
                                    
                                    HStack {
                                        Image(systemName: "star.fill")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                        Text(String(format: "%.1f", store.rating))
                                            .font(.caption)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ara")
        .onAppear { loadRecentSearches() }
    }
    
    private func performSearch() {
        guard !searchText.isEmpty else { return }
        
        // Add to recent searches
        if !recentSearches.contains(searchText) {
            recentSearches.insert(searchText, at: 0)
            if recentSearches.count > 10 {
                recentSearches = Array(recentSearches.prefix(10))
            }
            saveRecentSearches()
        }
        
        isSearching = true
        
        // TODO: Call API
        // Mock search results for now
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSearching = false
            // searchResults will be populated from API
        }
    }
    
    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: recentKey) ?? []
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: recentKey)
    }
}

// MARK: - Notification List View
struct NotificationListView: View {
    @ObservedObject var notificationManager = NotificationManager.shared
    
    var body: some View {
        List {
            if notificationManager.notifications.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("Bildirim yok")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 50)
                .listRowBackground(Color.clear)
            } else {
                ForEach(notificationManager.notifications) { notification in
                    NotificationRowView(notification: notification)
                        .onTapGesture {
                            notificationManager.markAsRead(notification.id)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                notificationManager.deleteNotification(notification.id)
                            } label: {
                                Label("Sil", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Bildirimler")
        .toolbar {
            if !notificationManager.notifications.isEmpty {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Tümünü Oku") {
                        notificationManager.markAllAsRead()
                    }
                }
            }
        }
    }
}

struct NotificationRowView: View {
    let notification: AppNotificationItem
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notification.type.icon)
                .font(.title2)
                .foregroundColor(Color(hex: notification.type.color))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.subheadline)
                    .fontWeight(notification.isRead ? .regular : .semibold)
                
                Text(notification.body)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(timeAgo(from: notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            if !notification.isRead {
                Circle()
                    .fill(Color.primaryGreen)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
        .opacity(notification.isRead ? 0.7 : 1.0)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Campaign Countdown Timer
struct CampaignCountdownView: View {
    let endDate: Date
    @State private var timeRemaining: String = ""
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption)
            Text(timeRemaining)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.red)
        .cornerRadius(4)
        .onAppear { updateTimeRemaining() }
        .onReceive(timer) { _ in updateTimeRemaining() }
    }
    
    private func updateTimeRemaining() {
        let now = Date()
        let remaining = endDate.timeIntervalSince(now)
        
        if remaining <= 0 {
            timeRemaining = "Bitti"
            return
        }
        
        let hours = Int(remaining) / 3600
        let minutes = (Int(remaining) % 3600) / 60
        let seconds = Int(remaining) % 60
        
        if hours > 24 {
            let days = hours / 24
            timeRemaining = "\(days) gün kaldı"
        } else if hours > 0 {
            timeRemaining = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            timeRemaining = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Map Filter View
struct MapFilterView: View {
    @Binding var selectedCategories: Set<String>
    @Binding var showOnlyOpen: Bool
    @Binding var maxDistance: Double
    @Environment(\.dismiss) var dismiss
    
    let categories = [
        ("market", "Market", "cart.fill"),
        ("restaurant", "Restoran", "fork.knife"),
        ("pharmacy", "Eczane", "cross.fill"),
        ("taxi", "Taksi", "car.fill"),
        ("courier", "Kurye", "shippingbox.fill")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Kategoriler") {
                    ForEach(categories, id: \.0) { (id, name, icon) in
                        Toggle(isOn: Binding(
                            get: { selectedCategories.contains(id) },
                            set: { isOn in
                                if isOn {
                                    selectedCategories.insert(id)
                                } else {
                                    selectedCategories.remove(id)
                                }
                            }
                        )) {
                            HStack {
                                Image(systemName: icon)
                                    .foregroundColor(.primaryGreen)
                                Text(name)
                            }
                        }
                    }
                }
                
                Section("Durum") {
                    Toggle("Sadece Açık Olanlar", isOn: $showOnlyOpen)
                }
                
                Section("Mesafe") {
                    VStack(alignment: .leading) {
                        Text("Maksimum: \(Int(maxDistance)) km")
                        Slider(value: $maxDistance, in: 1...50, step: 1)
                    }
                }
                
                Section {
                    Button("Filtreleri Temizle") {
                        selectedCategories = Set(categories.map { $0.0 })
                        showOnlyOpen = false
                        maxDistance = 10
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Filtrele")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Uygula") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Support") {
    NavigationStack {
        SupportView()
    }
}

#Preview("Rating") {
    RatingView(
        type: .vendor,
        targetId: "1",
        targetName: "Yunus Market",
        targetImage: nil,
        orderId: nil,
        rideId: nil,
        onComplete: {}
    )
}

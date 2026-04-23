import SwiftUI
import FirebaseAuth

struct DailyPromptView: View {
    @State private var isWriting = false
    @State private var writingKeyword: String = ""
    @State private var currentMonth: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var monthCards: [MonthCard] = []
    @State private var essays: [String: Essay] = [:]
    @State private var selectedEssay: Essay? = nil
    @State private var showingEssayDetail = false
    @State private var keywordCounts: [String: Int] = [:]
    @State private var showingBrowseView = false
    @State private var browseKeyword: String = ""

    @State private var scrollToDay: Int? = nil
    @State private var shouldScrollAfterLoad = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack {
                    // Beige background
                    Color(hex: "F5F0E8")
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Sticky month header
                        monthSelector
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color(hex: "F5F0E8"))

                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                // Cards for each day of month
                                ForEach(monthCards) { card in
                                    cardView(for: card)
                                        .id("\(currentMonth)-\(card.day)") // Unique ID with month
                                }
                            }
                            .id(currentMonth) // Force rebuild when month changes
                            .padding(.horizontal, 20)
                            .padding(.vertical, 8)
                            .padding(.bottom, 100)
                        }
                    }
                    .onChange(of: scrollToDay) { oldValue, newDay in
                        print("[DEBUG] onChange scrollToDay: old=\(oldValue ?? -1), new=\(newDay ?? -1)")
                        // Don't scroll here - wait for cards to be generated
                        // Scroll will happen in onChange(of: monthCards.count)
                    }
                    .onChange(of: monthCards.count) { oldCount, newCount in
                        // Only scroll if we have cards and shouldScrollAfterLoad is true
                        if let day = scrollToDay, newCount > 0, shouldScrollAfterLoad {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("\(currentMonth)-\(day)", anchor: .center)
                                    print("[DEBUG] Scrolled to day \(day) after \(newCount) cards")
                                }
                                shouldScrollAfterLoad = false
                                scrollToDay = nil
                            }
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $isWriting) {
                SimpleWritingEditorView(keyword: writingKeyword)
            }
            .sheet(item: $selectedEssay) { essay in
                EssayDetailView(essay: essay)
            }
            .sheet(isPresented: $showingBrowseView) {
                KeywordBrowseView(keyword: browseKeyword)
            }
            .task {
                // Calculate scroll target first
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
                let isCurrentMonth = calendar.isDate(currentMonth, equalTo: Date(), toGranularity: .month)
                scrollToDay = isCurrentMonth ? calendar.component(.day, from: Date()) : 1
                shouldScrollAfterLoad = true
                print("[DEBUG] Task - scrollToDay set to \(scrollToDay ?? 0), isCurrentMonth: \(isCurrentMonth)")

                // Then load data
                loadMonthData()
            }
            .onChange(of: currentMonth) { oldValue, newValue in
                print("[DEBUG] Month changed from \(oldValue) to \(newValue)")

                // Calculate new scroll target
                var calendar = Calendar.current
                calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current
                let isCurrentMonth = calendar.isDate(newValue, equalTo: Date(), toGranularity: .month)
                scrollToDay = isCurrentMonth ? calendar.component(.day, from: Date()) : 1
                shouldScrollAfterLoad = true
                print("[DEBUG] Month change - scrollToDay set to \(scrollToDay ?? 0)")

                loadMonthData()
            }
        }
    }

    // MARK: - Month Selector
    private var monthSelector: some View {
        HStack {
            // Previous month button - disabled at March 2026
            Button {
                print("[DEBUG] Previous month button clicked")
                withAnimation {
                    let newDate = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                    currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? newDate
                    print("[DEBUG] currentMonth updated to: \(currentMonth)")
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(isAtMinimumMonth)
            .foregroundStyle(isAtMinimumMonth ? .gray : .primary)

            Spacer()

            Text(monthYearString(from: currentMonth))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)

            Spacer()

            // Next month button - disabled at current month
            Button {
                print("[DEBUG] Next month button clicked")
                withAnimation {
                    let newDate = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                    currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: newDate)) ?? newDate
                    print("[DEBUG] currentMonth updated to: \(currentMonth)")
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 36, height: 36)
            }
            .disabled(isAtMaximumMonth)
            .foregroundStyle(isAtMaximumMonth ? .gray : .primary)
        }
    }

    // MARK: - Month Limits
    private var isAtMinimumMonth: Bool {
        // Minimum: March 2026
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 1
        guard let minimumDate = calendar.date(from: components) else { return false }
        return currentMonth <= minimumDate
    }

    private var isAtMaximumMonth: Bool {
        // Maximum: current month (today), NOT next month
        let today = Date()
        let todayYear = calendar.component(.year, from: today)
        let todayMonth = calendar.component(.month, from: today)
        let selectedYear = calendar.component(.year, from: currentMonth)
        let selectedMonth = calendar.component(.month, from: currentMonth)
        return selectedYear > todayYear || (selectedYear == todayYear && selectedMonth >= todayMonth)
    }

    private func monthYearString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "M월 yyyy"
        return formatter.string(from: date)
    }

    // MARK: - Data Loading
    private func loadMonthData() {
        print("[DEBUG] loadMonthData() called, currentMonth: \(currentMonth)")

        // Clear previous data immediately
        keywordCounts = [:]
        essays = [:]
        monthCards = [] // Clear old cards immediately

        // Generate cards with Firestore keywords in background
        Task {
            await generateMonthCardsAsync()
        }
    }

    /// Async version that loads real keywords from Firestore
    private func generateMonthCardsAsync() async {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "Asia/Seoul") ?? TimeZone.current

        let year = calendar.component(.year, from: currentMonth)
        let month = calendar.component(.month, from: currentMonth)
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0

        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart),
              let lastDay = calendar.date(byAdding: .day, value: -1, to: monthEnd) else { return }

        let todayStart = calendar.startOfDay(for: Date())
        let todayMonthStart = calendar.startOfDay(for: Date())
        let isFutureMonth = monthStart > todayMonthStart

        print("[DEBUG] Async generating cards for month: \(month), year: \(year), isFutureMonth: \(isFutureMonth)")

        // For future months: skip Firestore, use hash keywords (locked anyway)
        // For current/past months: load from Firestore

        var cards: [MonthCard] = []
        var currentDate = monthStart

        while currentDate <= lastDay {
            let day = calendar.component(.day, from: currentDate)

            // Determine if this specific day is in the future
            let isFutureDay = currentDate > todayStart

            // Use hash-based keyword for future (fast), Firestore for past/current
            let keyword: String
            if isFutureMonth || isFutureDay {
                // Fast path: hash-based, no Firestore call
                keyword = KeywordsService.shared.getStableKeyword(for: currentDate, language: .korean)
            } else {
                // Slow path: Firestore
                keyword = await KeywordsService.shared.getDisplayKeyword(for: currentDate, language: .korean)
            }

            let isSameDay = calendar.isDate(currentDate, inSameDayAs: Date())
            let isToday = isSameDay
            let isPast = !isToday && currentDate < todayStart
            let isFuture = isFutureDay || isFutureMonth

            let backgroundColor: String
            if isFuture {
                backgroundColor = "C2441C" // Burnt Nectar - locked
            } else if isToday {
                backgroundColor = "0D244D" // Indigo Rain - today
            } else if isPast {
                backgroundColor = "852E47" // Ruby Leaf - missed
            } else {
                backgroundColor = "C2441C"
            }

            let card = MonthCard(
                day: day,
                date: currentDate,
                keyword: keyword,
                isToday: isToday,
                isPast: isPast,
                isFuture: isFuture,
                backgroundColor: backgroundColor
            )
            cards.append(card)

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        await MainActor.run {
            monthCards = cards
            print("[DEBUG] Generated \(cards.count) cards (future month: \(isFutureMonth))")
        }

        // Only load essay data for non-future months
        if !isFutureMonth {
            await loadEssaysAndCounts()
        }
    }

    private func loadEssaysAndCounts() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        do {
            let monthEssays = try await FirebaseService.shared.getEssaysForMonth(userId: userId, date: currentMonth)

            var essayDict: [String: Essay] = [:]
            for essay in monthEssays {
                if essay.deletedAt != nil { continue }
                if essayDict[essay.keyword] == nil {
                    essayDict[essay.keyword] = essay
                }
            }

            await MainActor.run {
                essays = essayDict
            }

            var counts: [String: Int] = [:]
            try await withThrowingTaskGroup(of: (String, Int).self) { group in
                for card in monthCards {
                    group.addTask {
                        do {
                            let count = try await FirebaseService.shared.getEssayCountForKeyword(keyword: card.keyword)
                            return (card.keyword, count)
                        } catch {
                            return (card.keyword, 0)
                        }
                    }
                }

                for try await (keyword, count) in group {
                    counts[keyword] = count
                }
            }

            await MainActor.run {
                keywordCounts = counts
            }
        } catch {
            print("Error loading essays: \(error)")
        }
    }

    private func generateMonthCards() {
        // Deprecated: use generateMonthCardsAsync instead
        Task {
            await generateMonthCardsAsync()
        }
    }

    // MARK: - Card View Helper
    @ViewBuilder
    private func cardView(for card: MonthCard) -> some View {
        MonthCardView(
            card: card,
            essay: essays[card.keyword],
            onWrite: {
                writingKeyword = card.keyword
                isWriting = true
            },
            onViewEssay: {
                if let essay = essays[card.keyword] {
                    selectedEssay = essay
                    showingEssayDetail = true
                }
            },
            onBrowse: {
                browseKeyword = card.keyword
                showingBrowseView = true
            }
        )
    }
}

// MARK: - Month Card Model
struct MonthCard: Identifiable {
    let id: String  // day + date string for stable identity
    let day: Int
    let date: Date
    let keyword: String
    let isToday: Bool
    let isPast: Bool
    let isFuture: Bool
    let backgroundColor: String

    init(day: Int, date: Date, keyword: String, isToday: Bool, isPast: Bool, isFuture: Bool, backgroundColor: String) {
        self.id = "\(day)-\(ISO8601DateFormatter().string(from: date))"
        self.day = day
        self.date = date
        self.keyword = keyword
        self.isToday = isToday
        self.isPast = isPast
        self.isFuture = isFuture
        self.backgroundColor = backgroundColor
    }
}

// MARK: - Month Card View with Ragged Edges
struct MonthCardView: View {
    let card: MonthCard
    let essay: Essay?
    let onWrite: () -> Void
    let onViewEssay: () -> Void
    let onBrowse: () -> Void

    @State private var isFlipped = false

    private var isLocked: Bool { card.isFuture }

    private var cardBackground: Color {
        // If essay loaded, show done color; otherwise use pre-computed color
        if essay != nil { return Color(hex: "4A5A30") } // Moss Shadow - done
        return Color(hex: card.backgroundColor) // Pre-computed: locked/today/past
    }

    private var cardForegroundColor: Color {
        // Smooth transition between states
        essay != nil ? Color.white : Color.white
    }

    private var isWritten: Bool { essay != nil }
    private var isToday: Bool { card.isToday }
    private var isFuture: Bool { !card.isToday && !card.isPast }

    var body: some View {
        ZStack {
            // Front card
            frontCard
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                .opacity(isFlipped ? 0 : 1)

            // Back card (only for non-locked dates)
            if !isLocked {
                backCard
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 1 : 0)
            }
        }
        .frame(height: 180)
        .animation(.easeInOut(duration: 0.4), value: isFlipped)
        .animation(.easeInOut(duration: 0.3), value: essay?.id) // Smooth color transition
        .onTapGesture {
            if !isLocked {
                isFlipped.toggle()
            }
        }
    }

    // MARK: - Front Card
    private var frontCard: some View {
        TicketShape(teethCount: 28, toothDepth: 6)
            .fill(cardBackground)
            .overlay(
                VStack(spacing: 0) {
                    // Top: Day number and weekday
                    HStack {
                        Text("\(card.day)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(.white)

                        Text(dayOfWeekString(from: card.date).uppercased())
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.leading, 8)

                        Spacer()

                        // Status stamp
                        statusStamp
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer()

                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Bottom stats
                    HStack(spacing: 0) {
                        statItem(title: "WRITERS", value: "\(essay?.likesCount ?? 0)")
                        Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 30)
                        statItem(title: "STATUS", value: isWritten ? "Done" : isToday ? "Today" : card.isPast ? "Missed" : "Empty")
                        Rectangle().fill(Color.white.opacity(0.2)).frame(width: 1, height: 30)
                        statItem(title: "WORDS", value: isWritten ? "\(essay?.wordCount ?? 0)" : "-")
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            )
            .shadow(color: cardBackground.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    // MARK: - Back Card
    private var backCard: some View {
        TicketShape(teethCount: 28, toothDepth: 6)
            .fill(Color(hex: "F5F0E8"))
            .overlay(
                VStack(spacing: 0) {
                    // Keyword - more space above
                    VStack {
                        Spacer().frame(height: 24)

                        Text(card.keyword.uppercased())
                            .font(.system(size: 32, weight: .black, design: .serif))
                            .foregroundColor(cardBackground)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        Spacer()
                    }

                    // Divider
                    Rectangle()
                        .fill(cardBackground.opacity(0.2))
                        .frame(height: 1)
                        .padding(.horizontal, 24)

                    // Actions
                    HStack(spacing: 0) {
                        if !isWritten {
                            Button(action: onWrite) {
                                Text(isToday ? "오늘의 글쓰기" : "작성하기")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }

                            Rectangle()
                                .fill(cardBackground.opacity(0.2))
                                .frame(width: 1)
                                .padding(.vertical, 8)

                            Button(action: onBrowse) {
                                Text("둘러보기")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        } else {
                            // When written, show both View and Browse
                            Button(action: onViewEssay) {
                                Text("보기")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }

                            Rectangle()
                                .fill(cardBackground.opacity(0.2))
                                .frame(width: 1)
                                .padding(.vertical, 8)

                            Button(action: onBrowse) {
                                Text("둘러보기")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(cardBackground)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Status Stamp
    private var statusStamp: some View {
        ZStack {
            if isWritten {
                // DONE stamp - rubber stamp with thick border
                ZStack {
                    // Thick outer border
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white, lineWidth: 4)
                        .frame(width: 90, height: 46)

                    // Inner thin line
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        .frame(width: 82, height: 38)

                    // Text - bold and stamped look
                    Text("DONE")
                        .font(.system(size: 24, weight: .black))
                        .tracking(2)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 1, y: 1)
                }
                .rotationEffect(.degrees(-5))
            } else if isToday {
                // TODAY stamp - with horizontal lines like clearance stamp
                ZStack {
                    // Top line
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 72, height: 2)
                        .offset(y: -14)

                    // Bottom line
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 72, height: 2)
                        .offset(y: 14)

                    // Text
                    Text("TODAY")
                        .font(.system(size: 14, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.3), radius: 1, x: 1, y: 1)
                }
                .rotationEffect(.degrees(-5))
            } else if card.isPast {
                // MISSED stamp - faded rotated
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.5), lineWidth: 3)
                        .frame(width: 88, height: 44)

                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: 80, height: 36)

                    Text("MISSED")
                        .font(.system(size: 18, weight: .black))
                        .tracking(1)
                        .foregroundColor(.white.opacity(0.75))
                        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 1, y: 1)
                }
                .rotationEffect(.degrees(-5))
            } else {
                // FUTURE - locked
                Image(systemName: "lock.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 50, height: 50)
            }
        }
    }

    // MARK: - Stat Item
    private func statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .tracking(0.5)

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}

// MARK: - Ticket Shape (Zigzag Perforated Edges)
struct TicketShape: Shape {
    var teethCount: Int = 24
    var toothDepth: CGFloat = 6

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let toothWidth = rect.width / CGFloat(teethCount)
        let halfTooth = toothWidth / 2

        // Start at top-left
        path.move(to: CGPoint(x: 0, y: toothDepth))

        // Top edge with zigzag
        for i in 0..<teethCount {
            let x = CGFloat(i) * toothWidth
            path.addLine(to: CGPoint(x: x + halfTooth, y: toothDepth))
            if i < teethCount - 1 {
                path.addLine(to: CGPoint(x: x + toothWidth, y: 0))
            }
        }

        // Right edge
        path.addLine(to: CGPoint(x: rect.width, y: toothDepth))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - toothDepth))

        // Bottom edge with zigzag
        for i in (0..<teethCount).reversed() {
            let x = CGFloat(i) * toothWidth
            path.addLine(to: CGPoint(x: x + halfTooth, y: rect.height - toothDepth))
            if i > 0 {
                path.addLine(to: CGPoint(x: x, y: rect.height))
            }
        }

        // Left edge
        path.addLine(to: CGPoint(x: 0, y: rect.height - toothDepth))
        path.addLine(to: CGPoint(x: 0, y: toothDepth))

        return path
    }
}

// MARK: - Date Extension
extension Date {
    var month: Int {
        Calendar.current.component(.month, from: self)
    }
}

#Preview {
    DailyPromptView()
}

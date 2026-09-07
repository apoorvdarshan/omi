import SwiftUI

struct HomeView: View {
    @Environment(SeedStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                todaySection
                recapsSection
                conversationsSection
                Color.clear.frame(height: 8)
            }
        }
        .omiScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 10) {
            HomeComposerBar(
                isRecording: store.isRecording,
                onAsk: { store.openChat() },
                onMic: { store.openChat(voice: true) },
                onRecord: { store.isRecording.toggle() }
            )
        }
    }

    private var todaySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Today") {
                store.selectedTab = 2
            }
            VStack(spacing: 0) {
                ForEach(Array(store.todayTasks.enumerated()), id: \.element.id) { index, task in
                    if index > 0 {
                        Divider().background(.white.opacity(0.08))
                    }
                    Button {
                        store.toggleTask(task.id)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            TaskMark(completed: task.completed)
                            Text(task.title)
                                .font(.system(size: 16))
                                .foregroundStyle(task.completed ? Color.white.opacity(0.4) : .white)
                                .strikethrough(task.completed)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 11)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .omiSurface(radius: 20)
            .padding(.horizontal, 16)
        }
    }

    private var recapsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Daily Recaps") {
                store.showDailyRecaps = true
                store.selectedTab = 1
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.recaps) { recap in
                        NavigationLink {
                            DailyRecapDetailView(recap: recap)
                        } label: {
                            DailyRecapCard(recap: recap)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: "Conversations") {
                store.showDailyRecaps = false
                store.selectedTab = 1
            }
            VStack(spacing: 0) {
                ForEach(Array(store.conversations.sorted { $0.startedAt > $1.startedAt }.prefix(3).enumerated()), id: \.element.id) { index, conversation in
                    if index > 0 {
                        Divider().background(.white.opacity(0.08)).padding(.leading, 60)
                    }
                    NavigationLink {
                        ConversationDetailView(conversation: conversation)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                    .buttonStyle(.plain)
                }
            }
            .omiSurface(radius: 20)
            .padding(.horizontal, 16)
        }
    }
}

struct DailyRecapCard: View {
    let recap: DailyRecap

    private var accent: Color {
        switch recap.emoji {
        case "🚀": return Color(red: 1.0, green: 0.55, blue: 0.22)
        case "🌙": return Color(red: 0.45, green: 0.62, blue: 1.0)
        default: return Color.white.opacity(0.45)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                Text(recap.emoji)
                    .font(.system(size: 22))
                    .frame(width: 40, height: 40)
                    .background(accent.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(recap.date.recapLabel.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(.white.opacity(0.38))
                Spacer(minLength: 0)
            }
            Text(recap.headline)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            Text(recap.overview)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(2)
                .lineSpacing(2)
            Spacer(minLength: 0)
            HStack(spacing: 6) {
                recapStat("\(recap.conversationCount) convos")
                recapStat("\(recap.durationMinutes)m")
            }
        }
        .padding(16)
        .frame(width: 260, height: 172, alignment: .topLeading)
        .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func recapStat(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(.white.opacity(0.55))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.08), in: Capsule())
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack(spacing: 12) {
            Text(conversation.emoji)
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(OmiTheme.tertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(conversation.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if conversation.starred {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(OmiTheme.amber)
                    }
                }
                Text("\(conversation.startedAt.timeLabel) · \(conversation.minutes)m")
                    .font(.system(size: 13))
                    .foregroundStyle(OmiTheme.meta)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct TaskMark: View {
    let completed: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(completed ? OmiTheme.amber : Color.white.opacity(0.28), lineWidth: 1.6)
            if completed {
                Circle().fill(OmiTheme.amber)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
            }
        }
        .frame(width: 20, height: 20)
        .padding(.top, 2)
    }
}

extension Date {
    var timeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var recapLabel: String {
        if Calendar.current.isDateInToday(self) { return "Today" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }

    var dayHeader: String? {
        if Calendar.current.isDateInToday(self) { return nil }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: self)
    }
}

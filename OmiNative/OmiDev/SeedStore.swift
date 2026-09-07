import Foundation
import SwiftUI

@Observable
final class SeedStore {
    var conversations: [Conversation]
    var tasks: [TaskItem]
    var recaps: [DailyRecap]
    var messages: [ChatMessage]
    var apps: [OmiAppItem]
    var goals: [GoalItem]
    var memories: [MemoryItem]
    var selectedTab = 0
    var showCompletedTasks = false
    var conversationQuery = ""
    var taskQuery = ""
    var appQuery = ""
    var showDailyRecaps = false
    var showStarredOnly = false
    var isRecording = false
    var draft = ""
    var isChatPresented = false
    var chatAutoVoice = false

    func openChat(voice: Bool = false) {
        chatAutoVoice = voice
        isChatPresented = true
    }

    let userName = "Apoorv"

    init() {
        let now = Date()
        func ago(days: Int = 0, hours: Int = 0, minutes: Int = 0) -> Date {
            Calendar.current.date(byAdding: DateComponents(day: -days, hour: -hours, minute: -minutes), to: now) ?? now
        }

        conversations = [
            Conversation(
                id: "seed-standup",
                emoji: "☕",
                title: "Morning standup",
                overview: "You walked through Omi Dev UI work, the language-save bug, and what to ship next on Home.",
                startedAt: ago(hours: 1),
                minutes: 18,
                starred: true,
                category: "work",
                transcript: [
                    TranscriptLine(id: "s0", isUser: true, speaker: "You", text: "You walked through Omi Dev UI work, the language-save bug, and what to ship next on Home."),
                    TranscriptLine(id: "s1", isUser: false, speaker: "Maya", text: "Sounds good — I will follow up on the action items."),
                ],
                actions: ["Sketch the empty Home state", "Seed debug data for every tab"]
            ),
            Conversation(
                id: "seed-gym",
                emoji: "🏋️",
                title: "Gym session notes",
                overview: "Push day: bench, overhead press, and dips. You wanted more protein at dinner.",
                startedAt: ago(hours: 5),
                minutes: 42,
                starred: false,
                category: "personal",
                transcript: [
                    TranscriptLine(id: "g0", isUser: true, speaker: "You", text: "Push day: bench, overhead press, and dips. You wanted more protein at dinner."),
                    TranscriptLine(id: "g1", isUser: false, speaker: "Coach", text: "Log dinner protein so the week stays on track."),
                ],
                actions: ["Log dinner protein"]
            ),
            Conversation(
                id: "seed-design",
                emoji: "🎨",
                title: "Design review: onboarding",
                overview: "The sign-in wall is too heavy for local UI work. Home should open with real-looking content.",
                startedAt: ago(days: 1, hours: 3),
                minutes: 27,
                starred: false,
                category: "work",
                transcript: [
                    TranscriptLine(id: "d0", isUser: true, speaker: "You", text: "The sign-in wall is too heavy for local UI work."),
                    TranscriptLine(id: "d1", isUser: false, speaker: "Nina", text: "Home should open with real-looking content."),
                ],
                actions: ["Remove auth gate in debug", "Fill tabs with sample cards"]
            ),
            Conversation(
                id: "seed-dinner",
                emoji: "🍜",
                title: "Dinner with friends",
                overview: "Talked travel plans for later this year and a weekend hike near Delhi.",
                startedAt: ago(days: 2),
                minutes: 35,
                starred: false,
                category: "social",
                transcript: [
                    TranscriptLine(id: "n0", isUser: true, speaker: "You", text: "Talked travel plans for later this year and a weekend hike near Delhi."),
                    TranscriptLine(id: "n1", isUser: false, speaker: "Arjun", text: "Weekend hike is still on."),
                ],
                actions: []
            ),
            Conversation(
                id: "seed-call",
                emoji: "📞",
                title: "Quick call with backend",
                overview: "Agreed local debug can skip Firebase and keep language + home data on device.",
                startedAt: ago(days: 3, hours: 2),
                minutes: 14,
                starred: false,
                category: "work",
                transcript: [
                    TranscriptLine(id: "c0", isUser: true, speaker: "You", text: "Local debug can skip Firebase."),
                    TranscriptLine(id: "c1", isUser: false, speaker: "Backend", text: "Keep language and home data on device."),
                ],
                actions: []
            ),
        ]

        let todayEvening = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
        tasks = [
            TaskItem(id: "task-1", title: "Polish Home recaps card spacing", completed: false, dueAt: todayEvening, priority: "high", conversationId: "seed-standup"),
            TaskItem(id: "task-2", title: "Try Conversations, Tasks, and Apps tabs", completed: false, dueAt: todayEvening.addingTimeInterval(-2 * 3600), priority: "medium", conversationId: "seed-design"),
            TaskItem(id: "task-3", title: "Log dinner protein", completed: false, dueAt: todayEvening, priority: "low", conversationId: "seed-gym"),
            TaskItem(id: "task-4", title: "Book weekend hike", completed: true, dueAt: ago(days: 1), priority: "low", conversationId: "seed-dinner"),
        ]

        recaps = [
            DailyRecap(
                id: "recap-today",
                date: now,
                emoji: "🚀",
                headline: "A builder day",
                overview: "You shipped a local debug path, talked design, and still made it to the gym.",
                conversationCount: 2,
                durationMinutes: 60,
                actionCount: 3,
                highlights: [RecapHighlight(id: "h1", topic: "Product", emoji: "🧩", summary: "Home needs seeded data so UI work is not blocked by auth.")],
                actions: ["Polish Home recaps card spacing", "Log dinner protein"]
            ),
            DailyRecap(
                id: "recap-yesterday",
                date: ago(days: 1),
                emoji: "🌙",
                headline: "Design and dinner",
                overview: "Onboarding felt heavy. Evening was social and easy.",
                conversationCount: 2,
                durationMinutes: 62,
                actionCount: 2,
                highlights: [RecapHighlight(id: "h2", topic: "Friends", emoji: "🥾", summary: "Weekend hike near Delhi is still on the table.")],
                actions: []
            ),
        ]

        messages = [
            ChatMessage(id: "msg-1", text: "What did I talk about at standup?", isUser: true, createdAt: ago(minutes: 40)),
            ChatMessage(id: "msg-2", text: "This morning you covered Omi Dev UI work, the language-save failure, and seeding Home so you can design without signing in.", isUser: false, createdAt: ago(minutes: 39)),
            ChatMessage(id: "msg-3", text: "Remind me of today's tasks.", isUser: true, createdAt: ago(minutes: 8)),
            ChatMessage(id: "msg-4", text: "You have three open tasks: polish Home recaps spacing, walk the main tabs, and log dinner protein.", isUser: false, createdAt: ago(minutes: 7)),
        ]

        apps = [
            OmiAppItem(id: "app-chat", name: "Omi Chat", author: "Omi", description: "Ask anything about your conversations and memories.", category: "Productivity", enabled: true, official: true, rating: 4.6, ratingCount: 128, emoji: "💬"),
            OmiAppItem(id: "app-summary", name: "Daily Recap", author: "Omi", description: "A short recap of what mattered today.", category: "Productivity", enabled: true, official: true, rating: 4.6, ratingCount: 128, emoji: "📅"),
            OmiAppItem(id: "app-workout", name: "Gym Coach", author: "Community", description: "Turns workout chatter into a simple training log.", category: "Health", enabled: false, official: false, rating: 4.6, ratingCount: 128, emoji: "🏋️"),
            OmiAppItem(id: "app-travel", name: "Trip Planner", author: "Community", description: "Extracts places and dates from your talks.", category: "Lifestyle", enabled: false, official: false, rating: 4.6, ratingCount: 128, emoji: "✈️"),
        ]

        goals = [
            GoalItem(id: "goal-ship", emoji: "🎯", title: "Ship Omi Dev UI", current: 6, target: 10, unit: nil),
            GoalItem(id: "goal-gym", emoji: "💪", title: "Workouts this week", current: 2, target: 4, unit: "sessions"),
        ]

        memories = [
            MemoryItem(id: "mem-1", content: "Apoorv is building Omi UI locally on iPhone without signing in.", category: "interesting"),
            MemoryItem(id: "mem-2", content: "Prefers working out in the evening and tracking protein.", category: "interesting"),
            MemoryItem(id: "mem-3", content: "Lives in Delhi and is planning a weekend hike.", category: "system"),
            MemoryItem(id: "mem-4", content: "Wants Home, Conversations, Tasks, and Apps to look fully populated in debug.", category: "manual"),
        ]
    }

    var todayTasks: [TaskItem] {
        tasks.filter { !$0.completed && $0.dueAt != nil }.prefix(3).map { $0 }
    }

    var filteredConversations: [Conversation] {
        conversations
            .filter { conversationQuery.isEmpty || $0.title.localizedCaseInsensitiveContains(conversationQuery) || $0.overview.localizedCaseInsensitiveContains(conversationQuery) }
            .filter { !showStarredOnly || $0.starred }
            .sorted { $0.startedAt > $1.startedAt }
    }

    var groupedConversations: [(Date, [Conversation])] {
        let calendar = Calendar.current
        let groups = Dictionary(grouping: filteredConversations) { calendar.startOfDay(for: $0.startedAt) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0]!.sorted { $0.startedAt > $1.startedAt }) }
    }

    func section(for task: TaskItem) -> TaskSection {
        if task.completed { return .completed }
        guard let due = task.dueAt else { return .noDeadline }
        let calendar = Calendar.current
        if due < calendar.startOfDay(for: Date()) { return .overdue }
        if calendar.isDateInToday(due) { return .today }
        if calendar.isDateInTomorrow(due) { return .tomorrow }
        return .later
    }

    func tasks(in section: TaskSection) -> [TaskItem] {
        tasks.filter {
            (taskQuery.isEmpty || $0.title.localizedCaseInsensitiveContains(taskQuery)) &&
            self.section(for: $0) == section
        }
    }

    func toggleTask(_ id: String) {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        tasks[index].completed.toggle()
    }

    func toggleApp(_ id: String) {
        guard let index = apps.firstIndex(where: { $0.id == id }) else { return }
        apps[index].enabled.toggle()
    }

    func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatMessage(id: UUID().uuidString, text: text, isUser: true, createdAt: Date()))
        draft = ""
        let reply: String
        if text.localizedCaseInsensitiveContains("task") {
            reply = "You still have three open tasks: polish Home recaps spacing, walk the main tabs, and log dinner protein."
        } else if text.localizedCaseInsensitiveContains("standup") || text.localizedCaseInsensitiveContains("morning") {
            reply = "Standup covered Omi Dev UI work, the language-save failure, and seeding Home so you can design without signing in."
        } else {
            reply = "From today's recap: you shipped a local debug path, talked design, and still made it to the gym."
        }
        messages.append(ChatMessage(id: UUID().uuidString, text: reply, isUser: false, createdAt: Date().addingTimeInterval(0.4)))
    }

    func conversation(id: String) -> Conversation? {
        conversations.first { $0.id == id }
    }
}

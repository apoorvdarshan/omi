import Foundation

struct Conversation: Identifiable, Hashable {
    let id: String
    var emoji: String
    var title: String
    var overview: String
    var startedAt: Date
    var minutes: Int
    var starred: Bool
    var category: String
    var transcript: [TranscriptLine]
    var actions: [String]
}

struct TranscriptLine: Identifiable, Hashable {
    let id: String
    var isUser: Bool
    var speaker: String
    var text: String
}

struct TaskItem: Identifiable, Hashable {
    let id: String
    var title: String
    var completed: Bool
    var dueAt: Date?
    var priority: String
    var conversationId: String?
}

struct DailyRecap: Identifiable, Hashable {
    let id: String
    var date: Date
    var emoji: String
    var headline: String
    var overview: String
    var conversationCount: Int
    var durationMinutes: Int
    var actionCount: Int
    var highlights: [RecapHighlight]
    var actions: [String]
}

struct RecapHighlight: Identifiable, Hashable {
    let id: String
    var topic: String
    var emoji: String
    var summary: String
}

struct ChatMessage: Identifiable, Hashable {
    let id: String
    var text: String
    var isUser: Bool
    var createdAt: Date
}

struct OmiAppItem: Identifiable, Hashable {
    let id: String
    var name: String
    var author: String
    var description: String
    var category: String
    var enabled: Bool
    var official: Bool
    var rating: Double
    var ratingCount: Int
    var emoji: String
}

struct GoalItem: Identifiable, Hashable {
    let id: String
    var emoji: String
    var title: String
    var current: Double
    var target: Double
    var unit: String?
}

struct MemoryItem: Identifiable, Hashable {
    let id: String
    var content: String
    var category: String
}

enum TaskSection: String, CaseIterable, Identifiable {
    case today = "TODAY"
    case tomorrow = "TOMORROW"
    case later = "LATER"
    case noDeadline = "NO DEADLINE"
    case overdue = "OVERDUE"
    case completed = "COMPLETED"
    var id: String { rawValue }
}

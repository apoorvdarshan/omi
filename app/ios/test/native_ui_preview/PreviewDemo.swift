import SwiftUI
import UIKit

/// Demo tour mode, launched with the "demo" argument (and "light" for the light appearance) to record the
/// production renderer with realistic synthetic content: no account, backend, real person or secret.
/// The fixture's debug overlays stay hidden, and each action a person takes moves the tour on: the system
/// tab bar switches roots, Home's controls push chat, the full conversation list and search, and lists
/// answer through the production toast and sheet presenters. Test-only; the other fixtures never take
/// this path.
@available(iOS 16.0, *)
struct PreviewDemoRoot: View {
    @StateObject private var demo = PreviewDemo()

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Group {
                    if demo.tab == "home" { NativeHomeView(state: demo.home) }
                    else { NativeSurfaceView(state: demo.surface(demo.tab)).id(demo.tab) }
                }.frame(maxHeight: .infinity)
                NativeSurfaceView(state: demo.tabs).frame(height: 98)
            }.ignoresSafeArea(edges: .bottom)
            // Pushed screens cover the root bar, as in the app.
            if let pushed = demo.pushed {
                NativeSurfaceView(state: demo.surface(pushed))
                    .background(Color(uiColor: PreviewDemo.groupedScreens.contains(pushed)
                        ? .systemGroupedBackground : .systemBackground).ignoresSafeArea())
                    .id(pushed)
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
    }
}

private typealias JSON = [String: Any]

@available(iOS 16.0, *)
@MainActor
final class PreviewDemo: ObservableObject {
    static let enabled = ProcessInfo.processInfo.arguments.contains("demo")
    static let groupedScreens: Set<String> = ["conversations", "search"]

    @Published private(set) var tab = "home"
    @Published private(set) var pushed: String?
    private(set) var home: NativeHomeState!
    private(set) var tabs: NativeSurfaceState!
    private var states: [String: NativeSurfaceState] = [:]
    private var raws: [String: JSON]
    private let homeRaw: JSON
    /// The chat history the owner delivers just after the chat mounts, as Dart projects it.
    private var chatHistory: [JSON]?
    private var chatDraft = ""
    private var questions = 0
    private var toastID = 0
    private var modalID = 0
    private lazy var toasts = NativeToastPresenter()
    private lazy var modal = NativeModalPresenter(rootController: {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController
    })

    init() {
        homeRaw = DemoContent.home()
        raws = DemoContent.surfaces()
        chatHistory = DemoContent.chatHistory()
        home = NativeHomeState(snapshot: try! NativeHomeSnapshot.decode(homeRaw)) { [weak self] method, id in
            guard let self else { return nil }
            return try await self.homeAction(method, id)
        }
        for (screen, raw) in raws {
            states[screen] = NativeSurfaceState(snapshot: try! NativeSurfaceSnapshot.decode(raw)) { [weak self] id, value in
                try await self?.perform(screen, id, value)
            }
        }
        tabs = states["tabs"]
    }

    func surface(_ screen: String) -> NativeSurfaceState { states[screen]! }

    // MARK: Navigation

    private func homeAction(_ method: String, _ id: String?) async throws -> NativeConversation? {
        switch method {
        case "detail": return try NativeHomeSnapshot.decode(homeRaw).conversation(id: id ?? "")
        case "chat": push("chat")
        case "browse": push("conversations")
        case "search": push("search")
        case "tasks", "settings": select(tab: method)
        default: break
        }
        return nil
    }

    private func push(_ screen: String) {
        withAnimation(.easeInOut(duration: 0.35)) { pushed = screen }
        if screen == "chat" { deliverChatHistory() }
    }

    /// Shows the chat's history once the pushed chat has mounted, so it opens at the latest message.
    private func deliverChatHistory() {
        guard let history = chatHistory else { return }
        chatHistory = nil
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            self?.publish("chat") { raw in
                raw["sections"] = [DemoContent.section("messages", "", history)]
                raw["loading"] = false
                raw["loadingLabel"] = "Thinking…"
            }
        }
    }

    private func pop() {
        withAnimation(.easeInOut(duration: 0.35)) { pushed = nil }
    }

    private func select(tab next: String) {
        publish("tabs") { raw in
            var navigation = raw["navigation"] as! JSON
            navigation["value"] = next
            raw["navigation"] = navigation
        }
        tab = next
    }

    // MARK: Commands

    private func perform(_ screen: String, _ id: String, _ value: Any?) async throws {
        if id.hasPrefix("_visible:") || id.hasPrefix("_hidden:") { return }
        switch (screen, id) {
        case ("tabs", "main_destination"): if let next = value as? String { select(tab: next) }
        case (_, "back"): pop()
        case ("tasks", "task_add"): presentNewTask()
        case ("tasks", _): task(id, value)
        case ("conversations", _): conversation(id, value)
        case ("chat", _): chat(id, value)
        case ("search", "_search"): search(value as? String ?? "")
        case ("memories", "graph_card"): push("graph")
        case ("graph", "graph_canvas"): highlight(value as? String ?? "")
        default: setValue(screen, id, value)
        }
    }

    /// Applies a new raw snapshot to a screen with the next revision.
    private func publish(_ screen: String, _ mutate: (inout JSON) -> Void) {
        var raw = raws[screen]!
        mutate(&raw)
        raw["revision"] = (raw["revision"] as? Int ?? 0) + 1
        raws[screen] = raw
        states[screen]?.update(try! NativeSurfaceSnapshot.decode(raw))
    }

    /// Rewrites every section row; returning nil removes the row.
    private static func mapRows(_ raw: inout JSON, _ transform: (JSON) -> JSON?) {
        var sections = raw["sections"] as! [JSON]
        for index in sections.indices {
            sections[index]["rows"] = (sections[index]["rows"] as! [JSON]).compactMap(transform)
        }
        raw["sections"] = sections
    }

    private func setValue(_ screen: String, _ id: String, _ value: Any?) {
        guard let value else { return }
        publish(screen) { raw in
            Self.mapRows(&raw) { row in
                guard row["id"] as? String == id,
                      ["text", "toggle", "choice", "segmented", "task"].contains(row["kind"] as? String ?? "") else { return row }
                var next = row
                next["value"] = value
                return next
            }
        }
    }

    private func task(_ id: String, _ value: Any?) {
        if value as? String == "delete" {
            publish("tasks") { raw in Self.mapRows(&raw) { $0["id"] as? String == id ? nil : $0 } }
            return
        }
        let done = value as? Bool ?? (value as? String == "complete")
        setValue("tasks", id, done)
        if done { toast("confirm", "Task completed", symbol: "checkmark.circle.fill", clearance: 64) }
    }

    private func addTask(_ title: String) {
        publish("tasks") { raw in
            var sections = raw["sections"] as! [JSON]
            guard let today = sections.firstIndex(where: { $0["id"] as? String == "today" }) else { return }
            var task = DemoContent.row("task-new-\(modalID)", title, "task", subtitle: "Today", value: false,
                                       options: [("complete", "Complete"), ("delete", "Delete")])
            task["swipeLeading"] = ["complete"]
            task["swipeTrailing"] = ["delete"]
            sections[today]["rows"] = [task] + (sections[today]["rows"] as! [JSON])
            raw["sections"] = sections
        }
        toast("confirm", "Task added", symbol: "checkmark.circle.fill", clearance: 64)
    }

    private func presentNewTask() {
        modalID += 1
        let due = DemoContent.row("due", "Due", "choice", value: "today",
                                  options: [("today", "Today"), ("tomorrow", "Tomorrow"), ("next_week", "Next week")])
        let rows = [DemoContent.row("draft", "Task", "text", value: ""), due,
                    DemoContent.row("remind", "Remind me", "toggle", value: true)]
        let snapshot = DemoContent.surface("New Task", toolbar: [DemoContent.row("cancel", "Cancel", "button"),
                                                                 DemoContent.row("save", "Add", "button")],
                                           sections: [DemoContent.section("task", "", rows,
                                                footer: "Omi also adds the tasks it hears in your conversations.")])
        let args: JSON = ["requestId": modalID, "cancelId": "cancel", "snapshot": snapshot, "alert": false,
            "dismissible": true, "guardEdits": true,
            "discard": ["title": "Discard Changes?", "message": "Your new task has not been saved.",
                        "confirm": "Discard", "cancel": "Keep Editing"]]
        try? modal.present(args) { [weak self] response in
            guard let response = response as? JSON, response["action"] as? String == "save",
                  let values = response["values"] as? JSON,
                  let title = (values["draft"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !title.isEmpty else { return }
            self?.addTask(title)
        }
    }

    private func conversation(_ id: String, _ value: Any?) {
        switch id {
        case "select":
            publish("conversations") { raw in
                let ids = DemoContent.conversations.filter { !$0.locked }.map(\.id)
                raw["selection"] = ["selected": [String](), "selectable": ids]
                raw["bottomBar"] = DemoContent.selectionBar(0)
                raw["toolbar"] = [DemoContent.row("selection_done", "Done", "button")]
            }
        case "selection_done":
            publish("conversations", Self.endSelection)
        case "_selection":
            let ids = value as? [String] ?? []
            publish("conversations") { raw in
                var selection = raw["selection"] as! JSON
                selection["selected"] = ids
                raw["selection"] = selection
                raw["bottomBar"] = DemoContent.selectionBar(ids.count)
            }
        case "bulk_delete":
            let selected = (raws["conversations"]?["selection"] as? JSON)?["selected"] as? [String] ?? []
            delete(Set(selected))
        default:
            if value as? String == "delete" { delete([id]) }
        }
    }

    private static func endSelection(_ raw: inout JSON) {
        raw.removeValue(forKey: "selection")
        raw.removeValue(forKey: "bottomBar")
        raw["toolbar"] = DemoContent.conversationsToolbar()
    }

    /// Removes the conversations and offers Undo, which restores them, as the app's undo toast does.
    private func delete(_ ids: Set<String>) {
        guard !ids.isEmpty, let before = raws["conversations"]?["sections"] else { return }
        publish("conversations") { raw in
            Self.mapRows(&raw) { ids.contains($0["id"] as? String ?? "") ? nil : $0 }
            Self.endSelection(&raw)
        }
        let message = ids.count == 1 ? "Conversation deleted" : "\(ids.count) conversations deleted"
        toast("undo", message, action: "Undo", symbol: "trash", clearance: 16) { [weak self] outcome in
            guard outcome == "action" else { return }
            self?.publish("conversations") { raw in raw["sections"] = before }
        }
    }

    private func chat(_ id: String, _ value: Any?) {
        switch id {
        case "chat_draft":
            chatDraft = value as? String ?? ""
            publish("chat") { raw in Self.setDraft(&raw, chatDraft) }
        case "chat_send":
            let question = chatDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            chatDraft = ""
            if !question.isEmpty { ask(question) }
        case "chat_followup":
            if let followup = (raws["chat"]?["chat"] as? JSON)?["followup"] as? String, !followup.isEmpty { ask(followup) }
        default: break
        }
    }

    private static func setDraft(_ raw: inout JSON, _ draft: String) {
        var chat = raw["chat"] as! JSON
        chat["draft"] = draft
        var actions = chat["actions"] as! [JSON]
        if let field = actions.firstIndex(where: { $0["id"] as? String == "chat_draft" }) { actions[field]["value"] = draft }
        chat["actions"] = actions
        raw["chat"] = chat
    }

    /// Shows the question at once, then streams the canned reply block by block.
    private func ask(_ question: String) {
        questions += 1
        let replyID = "demo_reply_\(questions)"
        let answer = DemoContent.answer(to: question)
        publish("chat") { raw in
            Self.appendMessage(&raw, DemoContent.message("demo_question_\(questions)", question, user: true))
            Self.setDraft(&raw, "")
            Self.setChat(&raw, streaming: true, followup: "")
        }
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            for count in 1...answer.blocks.count {
                self?.publish("chat") { raw in
                    let reply = DemoContent.reply(replyID, Array(answer.blocks.prefix(count)),
                                                  caption: count == answer.blocks.count ? answer.caption : "")
                    var sections = raw["sections"] as! [JSON]
                    var rows = sections[0]["rows"] as! [JSON]
                    if let index = rows.firstIndex(where: { $0["id"] as? String == replyID }) { rows[index] = reply }
                    else { rows.append(reply) }
                    sections[0]["rows"] = rows
                    raw["sections"] = sections
                    let done = count == answer.blocks.count
                    Self.setChat(&raw, streaming: !done, followup: done ? answer.followup : "")
                }
                try? await Task.sleep(nanoseconds: 280_000_000)
            }
        }
    }

    private static func appendMessage(_ raw: inout JSON, _ message: JSON) {
        var sections = raw["sections"] as! [JSON]
        sections[0]["rows"] = (sections[0]["rows"] as! [JSON]) + [message]
        raw["sections"] = sections
    }

    private static func setChat(_ raw: inout JSON, streaming: Bool, followup: String) {
        var chat = raw["chat"] as! JSON
        chat["streaming"] = streaming
        chat["followup"] = followup
        raw["chat"] = chat
    }

    private func search(_ query: String) {
        publish("search") { raw in
            raw["searchValue"] = query
            let trimmed = query.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                raw["sections"] = DemoContent.searchStart()
                raw["empty"] = ""
            } else {
                let matches = DemoContent.conversations.filter {
                    !$0.locked && "\($0.title) \($0.keywords)".localizedCaseInsensitiveContains(trimmed)
                }
                raw["sections"] = [DemoContent.section("results", "Conversations", matches.map(DemoContent.listRow))]
                raw["empty"] = "No results for “\(trimmed)”"
            }
        }
    }

    private func highlight(_ node: String) {
        publish("graph") { raw in
            Self.mapRows(&raw) { row in
                guard row["id"] as? String == "graph_canvas", var graph = row["graph"] as? JSON else { return row }
                var next = row
                graph["highlighted"] = node.isEmpty ? [] : [node]
                next["graph"] = graph
                next["value"] = node
                return next
            }
        }
    }

    private func toast(_ kind: String, _ message: String, action: String? = nil, symbol: String, clearance: Double,
                       outcome: ((String) -> Void)? = nil) {
        toastID += 1
        var request: JSON = ["requestId": toastID, "session": "demo", "kind": kind, "message": message,
            "durationMs": NativeToastRequest.durations[kind] ?? 0, "symbol": symbol, "bottomClearance": clearance,
            "appearance": DemoContent.appearance, "locale": "en", "direction": "ltr"]
        if let action { request["actionLabel"] = action }
        try? toasts.show(request) { result in outcome?(result as? String ?? "") }
    }
}

// MARK: - Synthetic content

/// Realistic but invented content: common first names only, example.com addresses and no secrets.
private enum DemoContent {
    static let appearance = ProcessInfo.processInfo.arguments.contains("light") ? "light" : "dark"

    struct Conversation {
        let id: String, title: String, group: String, time: String, duration: String, symbol: String
        var starred = false
        var locked = false
        var keywords = ""
    }

    static let conversations: [Conversation] = [
        Conversation(id: "conv-product-sync", title: "Weekly product sync", group: "today", time: "9:02 AM", duration: "38 min",
                     symbol: "briefcase", starred: true, keywords: "Sarah Mike Priya beta launch onboarding firmware"),
        Conversation(id: "conv-coffee-sarah", title: "Coffee with Sarah", group: "today", time: "8:05 AM", duration: "24 min",
                     symbol: "cup.and.saucer", keywords: "Sarah offsite venue"),
        Conversation(id: "conv-morning-run", title: "Morning run notes", group: "today", time: "6:48 AM", duration: "6 min",
                     symbol: "figure.run", keywords: "running 5 km"),
        Conversation(id: "conv-podcast", title: "Podcast idea brainstorm", group: "yesterday", time: "9:05 PM", duration: "17 min",
                     symbol: "lightbulb", keywords: "wearables podcast"),
        Conversation(id: "conv-groceries", title: "Grocery list", group: "yesterday", time: "6:20 PM", duration: "3 min",
                     symbol: "cart", keywords: "oat milk"),
        Conversation(id: "conv-dentist", title: "Dentist appointment", group: "yesterday", time: "4:15 PM", duration: "22 min",
                     symbol: "cross.case", keywords: "follow-up cleaning"),
        Conversation(id: "conv-design-review", title: "Design review: onboarding", group: "yesterday", time: "2:00 PM",
                     duration: "51 min", symbol: "paintbrush", starred: true, keywords: "Priya Sarah permissions"),
        Conversation(id: "conv-one-on-one", title: "1:1 with Mike", group: "yesterday", time: "11:30 AM", duration: "30 min",
                     symbol: "person.2", locked: true),
        Conversation(id: "conv-investor", title: "Investor update prep", group: "week", time: "Wed, 3:40 PM", duration: "26 min",
                     symbol: "chart.line.uptrend.xyaxis", keywords: "metrics retention"),
        Conversation(id: "conv-team-lunch", title: "Team lunch", group: "week", time: "Wed, 12:30 PM", duration: "48 min",
                     symbol: "fork.knife", keywords: "Sarah Mike Priya"),
        Conversation(id: "conv-book-club", title: "Book club night", group: "week", time: "Tue, 8:00 PM", duration: "1 hr 12 min",
                     symbol: "book", starred: true, keywords: "Sarah science fiction"),
        Conversation(id: "conv-landlord", title: "Call with the landlord", group: "week", time: "Tue, 6:10 PM", duration: "12 min",
                     symbol: "house", locked: true),
        Conversation(id: "conv-retro", title: "Sprint retro", group: "week", time: "Mon, 4:00 PM", duration: "45 min",
                     symbol: "arrow.triangle.2.circlepath", keywords: "Mike Priya"),
        Conversation(id: "conv-flight", title: "Flight check-in reminder", group: "week", time: "Mon, 9:15 AM", duration: "2 min",
                     symbol: "airplane"),
    ]

    static let groups = [("today", "Today"), ("yesterday", "Yesterday"), ("week", "This Week")]

    static func row(_ id: String, _ title: String, _ kind: String, subtitle: String = "", symbol: String? = nil,
                    value: Any? = nil, options: [(String, String)] = [], enabled: Bool = true,
                    destructive: Bool = false) -> JSON {
        var row: JSON = ["id": id, "title": title, "kind": kind, "subtitle": subtitle, "enabled": enabled,
                         "destructive": destructive, "options": options.map { ["id": $0.0, "title": $0.1] }]
        if let symbol { row["symbol"] = symbol }
        if let value { row["value"] = value }
        return row
    }

    static func section(_ id: String, _ title: String, _ rows: [JSON], footer: String = "") -> JSON {
        ["id": id, "title": title, "footer": footer, "rows": rows]
    }

    static func surface(_ title: String, largeTitle: Bool = false, toolbar: [JSON] = [], sections: [JSON]) -> JSON {
        ["version": 1, "revision": 0, "title": title, "largeTitle": largeTitle, "appearance": appearance,
         "locale": "en", "direction": "ltr", "loading": false, "failed": false, "empty": "", "sections": sections,
         "toolbar": toolbar, "searchEnabled": false, "searchValue": "", "searchPlaceholder": "", "refreshEnabled": false,
         "error": "Something went wrong", "retry": "Try Again", "loadingLabel": "Thinking…"]
    }

    static func back() -> JSON { row("back", "Back", "button", symbol: "chevron.left") }

    static func surfaces() -> [String: JSON] {
        var tabs = surface("", sections: [])
        tabs["navigation"] = ["id": "main_destination", "title": "", "kind": "segmented", "subtitle": "", "value": "home",
            "enabled": true, "destructive": false,
            "options": ["home", "tasks", "memories", "apps", "settings"].map { ["id": $0, "title": $0.capitalized] }]
        return ["tabs": tabs, "tasks": tasks(), "memories": memories(), "apps": apps(), "settings": settings(),
                "chat": chat(), "conversations": conversationList(), "search": searchScreen(), "graph": graph()]
    }

    // MARK: Home

    static func home() -> JSON {
        func action(_ id: String, _ title: String, _ symbol: String) -> JSON {
            ["id": id, "title": title, "symbol": symbol, "enabled": true]
        }
        let recaps: [JSON] = [
            ["id": "recap-1", "title": "Launch prep, a long run and coffee with Sarah", "date": "Yesterday", "emoji": "🚀"],
            ["id": "recap-2", "title": "Design reviews and a podcast idea", "date": "Wed, Oct 7", "emoji": "🎨"],
            ["id": "recap-3", "title": "Book club night and sprint planning", "date": "Tue, Oct 6", "emoji": "📚"],
            ["id": "recap-4", "title": "A quiet Monday of deep work", "date": "Mon, Oct 5", "emoji": "🌿"],
        ]
        let capture: JSON = ["status": "Listening", "detail": "Omi pendant", "elapsed": "12:04", "source": "omi",
            "lastLine": "The venue has room for twelve, so we can invite the whole team.", "explanation": "",
            "actions": [action("pauseCapture", "Pause", "pause.fill")]]
        let chrome: JSON = ["home": "Home", "tasks": "Tasks", "ask": "Ask Omi", "recapsTitle": "Daily Recaps",
            "header": [action("device", "84%", "battery.75percent"), action("calls", "Phone Calls", "phone"),
                       action("sync", "Sync", "icloud"), action("search", "Search", "magnifyingglass"),
                       action("settings", "Settings", "gearshape")],
            "footer": [action("chat", "Ask Omi", "bubble.left"), action("voice", "Voice", "mic"),
                       action("record", "Record", "record.circle"), action("tasks", "Tasks", "checklist")],
            "alerts": [JSON](), "recaps": recaps, "capture": capture]
        let groups: [JSON] = Self.groups.map { group in
            ["id": group.0, "title": group.1,
             "conversations": conversations.filter { $0.group == group.0 }.map(homeConversation)]
        }
        let copy: JSON = ["conversations": "Conversations", "summary": "Summary", "transcript": "Transcript",
            "loading": "Loading…", "empty": "No conversations yet", "error": "Could not load conversations.",
            "retry": "Try again", "more": "More options", "viewAll": "View All", "loadMore": "Show more",
            "recordings": "Recordings", "noSummary": "No summary yet", "noTranscript": "No transcript available.",
            "starred": "Starred", "lockedHint": "Upgrade to Unlimited"]
        return ["version": 1, "revision": 1, "appearance": appearance, "locale": "en", "direction": "ltr",
                "loading": false, "failed": false, "hasMore": true, "localRecordingCount": 2, "groups": groups,
                "copy": copy, "chrome": chrome]
    }

    static func homeConversation(_ conversation: Conversation) -> JSON {
        var result: JSON = ["id": conversation.id, "title": conversation.title,
            "timestamp": "\(conversation.time) · \(conversation.duration)", "locked": conversation.locked,
            "starred": conversation.starred, "status": "completed"]
        guard !conversation.locked else { return result }
        let detail = conversation.id == "conv-product-sync" ? productSync() : brief(conversation)
        result["summary"] = detail.summary
        result["transcript"] = detail.transcript.enumerated().map { index, turn in
            ["id": "\(conversation.id):\(index)", "speaker": turn.0, "text": turn.1]
        }
        result["externalText"] = ""
        return result
    }

    static func productSync() -> (summary: String, transcript: [(String, String)]) {
        let summary = """
        **Overview**
        The team moved the beta invites to Thursday, so onboarding gets one more design pass and firmware 3.1 \
        reaches QA first.

        **Key points**
        • The beta cohort grew from 200 to about 500 testers
        • 18% of new users drop off at the permissions step
        • Firmware 3.1 fixes pairing and adds about 22% battery life
        • Beta pricing stays the same until retention data is in

        **Decisions**
        • Ask for Bluetooth only when the pendant pairs
        • Send the beta invites on Thursday

        **Action items**
        ☐ Priya: updated onboarding mocks by Tuesday
        ☐ Mike: firmware 3.1 build to QA by Wednesday
        ☐ Sarah: draft the beta announcement email
        ☑ You: share the drop-off funnel with the team

        **Open questions**
        • Should the beta include a second QA pass for pairing?
        • Which battery numbers go in the announcement?

        **Next sync**
        Same time next week, with a first look at the beta feedback.
        """
        let transcript = [
            ("You", "Okay, let's get started. Three things today: the beta date, onboarding and the firmware build."),
            ("Sarah", "Quick update first: the invite list is ready. We're at about 500 testers now, up from 200 last month."),
            ("You", "That's great. Are we still on track to send the invites on Tuesday?"),
            ("Mike", "I'd push it to Thursday. Firmware 3.1 fixes the pairing bug, and I want QA to have two full days with it."),
            ("Sarah", "Thursday works for marketing. It also gives Priya time for one more pass on onboarding."),
            ("You", "What are we seeing in the funnel right now?"),
            ("Sarah", "About 18 percent drop off at the permissions step. People don't see why we need Bluetooth and the microphone at the same time."),
            ("Mike", "We could ask for Bluetooth only when they pair the pendant. That's a small change on our side."),
            ("You", "Let's do that. Can the new flow make it into Priya's mocks by Tuesday?"),
            ("Sarah", "Yes, I'll sync with her right after this call."),
            ("Mike", "One more good thing: battery life on 3.1 is up about 22 percent in our overnight tests."),
            ("You", "Nice. That should go in the beta announcement."),
            ("Sarah", "I'll draft the email today and share it with everyone."),
            ("You", "Perfect. Pricing stays the same for the beta cohort until we see the retention numbers."),
            ("Mike", "Agreed. I'll have the 3.1 build to QA by Wednesday morning."),
            ("You", "Great, thanks everyone. Same time next week."),
        ]
        return (summary, transcript)
    }

    static func brief(_ conversation: Conversation) -> (summary: String, transcript: [(String, String)]) {
        let summary = "**Overview**\nA short \(conversation.duration) conversation, captured at \(conversation.time).\n\n"
            + "**Key points**\n• Omi kept the main points and the follow-ups in your tasks"
        return (summary, [("You", "Let me capture this before I forget."),
                          ("Speaker 1", "Sounds good. I'll send the details later today.")])
    }

    // MARK: Lists

    static func listRow(_ conversation: Conversation) -> JSON {
        var row = row(conversation.id, conversation.title, "navigation",
                      subtitle: "\(conversation.time) · \(conversation.duration)\(conversation.locked ? " · Locked" : "")",
                      symbol: conversation.starred ? "star.fill" : conversation.symbol,
                      options: [("open", "Open"), ("star", conversation.starred ? "Unstar" : "Star"), ("delete", "Delete")])
        row["swipeTrailing"] = ["delete"]
        return row
    }

    static func conversationsToolbar() -> [JSON] { [back(), row("select", "Select", "button")] }

    static func conversationList() -> JSON {
        surface("Conversations", toolbar: conversationsToolbar(), sections: groups.map { group in
            section(group.0, group.1, conversations.filter { $0.group == group.0 }.map(listRow))
        })
    }

    static func selectionBar(_ count: Int) -> [JSON] {
        [row("selection_count", count == 0 ? "Select conversations" : "\(count) selected", "label"),
         row("bulk_move", "Move to Folder", "button", symbol: "folder", enabled: count > 0),
         row("bulk_delete", "Delete", "button", symbol: "trash", enabled: count > 0, destructive: true)]
    }

    static func tasks() -> JSON {
        func task(_ id: String, _ title: String, _ subtitle: String, done: Bool = false) -> JSON {
            var task = row(id, title, "task", subtitle: subtitle, value: done,
                           options: [("complete", "Complete"), ("delete", "Delete")])
            task["swipeLeading"] = ["complete"]
            task["swipeTrailing"] = ["delete"]
            return task
        }
        return surface("Tasks", largeTitle: true, toolbar: [row("task_add", "New Task", "button", symbol: "plus")], sections: [
            section("overdue", "Overdue", [
                task("task-invoice", "Send the invoice to the design agency", "Due yesterday"),
                task("task-passport", "Renew passport", "Due Oct 2"),
            ]),
            section("today", "Today", [
                task("task-mocks", "Review Priya's onboarding mocks", "From Weekly product sync"),
                task("task-dentist", "Book the dentist follow-up", "From Dentist appointment"),
                task("task-venue", "Reply to Sarah about the venue", "From Coffee with Sarah"),
                task("task-funnel", "Share the drop-off funnel", "From Weekly product sync", done: true),
            ]),
            section("tomorrow", "Tomorrow", [
                task("task-beta-email", "Approve the beta announcement email", "From Weekly product sync"),
                task("task-oat-milk", "Buy oat milk and coffee beans", "From Grocery list"),
            ]),
            section("later", "Later", [
                task("task-offsite", "Plan the team offsite", "Next week"),
                task("task-book-club", "Read chapters 12–15 for book club", "Tue, Oct 13"),
                task("task-podcast", "Outline the first podcast episode", "From Podcast idea brainstorm"),
            ]),
        ])
    }

    static func memories() -> JSON {
        func memory(_ id: String, _ title: String, _ source: String) -> JSON {
            row(id, title, "navigation", subtitle: source, options: [("edit", "Edit"), ("delete", "Delete")])
        }
        var card = row("graph_card", "Memory Graph", "graph")
        card["graph"] = graphContent(layout: "card")
        return surface("Memories", largeTitle: true, sections: [
            section("mind_map", "", [card]),
            section("about", "About You", [
                memory("memory-running", "Runs 5 km most mornings before 7 AM", "From Morning run notes · Today"),
                memory("memory-coffee", "Prefers oat milk flat whites", "From Coffee with Sarah · Today"),
                memory("memory-allergy", "Is allergic to penicillin", "From Dentist appointment · Yesterday"),
            ]),
            section("work", "Work", [
                memory("memory-beta", "Leads product for the Omi beta", "From Weekly product sync · Today"),
                memory("memory-invites", "Beta invites go out on Thursday", "From Weekly product sync · Today"),
                memory("memory-firmware", "Mike owns the pendant firmware", "From Sprint retro · Mon"),
            ]),
            section("people", "People", [
                memory("memory-sarah", "Sarah is a designer and a friend from university", "From Coffee with Sarah · Today"),
                memory("memory-priya", "Priya is redesigning onboarding", "From Design review · Yesterday"),
            ]),
            section("interests", "Interests", [
                memory("memory-book-club", "Reads science fiction with a book club", "From Book club night · Tue"),
                memory("memory-podcast", "Wants to start a podcast about wearables", "From Podcast idea brainstorm · Yesterday"),
            ]),
        ])
    }

    static func graphContent(layout: String) -> JSON {
        func node(_ id: String, _ label: String, _ type: String, _ x: Double, _ y: Double, _ z: Double) -> JSON {
            ["id": id, "label": label, "type": type, "x": x, "y": y, "z": z, "fixed": id == "me"]
        }
        let nodes: [JSON] = [
            node("me", "You", "user", 0, 0, 0), node("sarah", "Sarah", "person", -120, -130, 80),
            node("priya", "Priya", "person", -10, -220, -120), node("beta", "October beta", "concept", 115, -170, 100),
            node("mike", "Mike", "person", 150, -60, -60), node("omi", "Omi", "organization", 145, 60, 40),
            node("pendant", "Pendant", "thing", 95, 150, 180), node("dentist", "Dentist", "place", 0, 225, 140),
            node("running", "Running", "concept", -100, 190, -120), node("book_club", "Book club", "concept", -150, 85, 60),
            node("scifi", "Science fiction", "concept", -60, 120, -260), node("cafe", "Corner café", "place", -155, -20, 200),
            node("onboarding", "Onboarding", "concept", 55, -95, -200), node("podcast", "Podcast idea", "concept", 40, 90, -180),
        ]
        let edges: [JSON] = [
            ("me", "sarah", "friend"), ("me", "mike", "works with"), ("me", "priya", "works with"), ("me", "omi", "works at"),
            ("omi", "pendant", "makes"), ("me", "pendant", "wears"), ("mike", "pendant", "firmware"), ("me", "beta", "leads"),
            ("beta", "onboarding", ""), ("priya", "onboarding", "designs"), ("sarah", "book_club", "hosts"),
            ("me", "book_club", "member"), ("book_club", "scifi", "reads"), ("me", "running", ""), ("me", "cafe", "visits"),
            ("sarah", "cafe", ""), ("me", "dentist", ""), ("me", "podcast", "idea"), ("sarah", "beta", "announces"),
        ].map { ["source": $0.0, "target": $0.1, "label": $0.2] }
        var graph: JSON = ["nodes": nodes, "edges": edges, "highlighted": [String](), "placeholder": false,
                           "accent": "#FFFFFF", "layout": layout]
        if layout == "card" {
            graph["zoom"] = 0.55
            graph["interactive"] = false
            graph["height"] = 180.0
        } else {
            graph["zoom"] = 0.9
            graph["interactive"] = true
        }
        return graph
    }

    static func graph() -> JSON {
        var canvas = row("graph_canvas", "Memory Graph", "graph", value: "")
        canvas["graph"] = graphContent(layout: "fill")
        return surface("Memory Graph", toolbar: [back(), row("graph_share", "Share", "button", symbol: "square.and.arrow.up")],
                       sections: [section("graph", "", [
                           row("graph_hint", "Tap a person, place or topic to see what connects to it.", "label"), canvas,
                       ])])
    }

    static func settings() -> JSON {
        func link(_ id: String, _ title: String, _ symbol: String, _ subtitle: String = "") -> JSON {
            row(id, title, "navigation", subtitle: subtitle, symbol: symbol)
        }
        return surface("Settings", largeTitle: true, sections: [
            section("account", "", [link("account", "Alex", "person.crop.circle.fill", "alex@example.com")]),
            section("plan", "", [link("plan", "Plan & Usage", "chart.xyaxis.line"), link("referral", "Referral Program", "gift", "NEW")]),
            section("device", "", [link("device", "Device", "antenna.radiowaves.left.and.right", "Omi pendant · 84%"),
                                   link("integrations", "Integrations", "point.3.connected.trianglepath.dotted", "BETA"),
                                   link("phone", "Phone Calls", "phone")]),
            section("preferences", "Preferences", [
                row("daily_recap", "Daily recap", "toggle", value: true),
                row("notifications", "Notifications", "toggle", value: true),
                row("language", "Language", "choice", value: "en",
                    options: [("en", "English"), ("es", "Español"), ("de", "Deutsch"), ("fr", "Français")]),
                link("privacy", "Privacy & Data", "hand.raised"),
            ], footer: "Omi sends a daily recap at 9 PM."),
            section("more", "", [link("developer", "Developer", "chevron.left.forwardslash.chevron.right"),
                                 link("help", "Help & Feedback", "questionmark.circle"),
                                 link("about", "About Omi", "info.circle", "Version 1.0.543")]),
            section("sign_out", "", [row("sign_out", "Sign Out", "button", destructive: true)]),
        ])
    }

    static func apps() -> JSON {
        func app(_ id: String, _ title: String, _ symbol: String, _ subtitle: String) -> JSON {
            row(id, title, "navigation", subtitle: subtitle, symbol: symbol)
        }
        return surface("Apps", largeTitle: true, sections: [
            section("installed", "Installed", [app("app-calendar", "Calendar Sync", "calendar", "Adds events you mention"),
                                               app("app-journal", "Daily Journal", "book.closed", "Writes a nightly entry")]),
            section("popular", "Popular", [app("app-coach", "Meeting Coach", "person.wave.2", "Feedback after each meeting"),
                                           app("app-tutor", "Language Tutor", "character.bubble", "Practice what you said")]),
        ])
    }

    // MARK: Search

    static func searchStart() -> [JSON] {
        [section("recent", "Recent Searches", ["beta launch", "dentist", "book club"].enumerated().map { index, query in
            row("recent-\(index)", query, "label", symbol: "clock.arrow.circlepath")
        }), section("starred", "Starred", conversations.filter(\.starred).map(listRow))]
    }

    static func searchScreen() -> JSON {
        var screen = surface("Search", toolbar: [back()], sections: searchStart())
        screen["searchEnabled"] = true
        screen["searchPlaceholder"] = "Search conversations"
        return screen
    }

    // MARK: Chat

    static func block(_ kind: String, _ text: String, prefix: String = "", indent: Int = 0, level: Int? = nil) -> JSON {
        var block: JSON = ["kind": kind, "text": text, "indent": indent, "prefix": prefix]
        if let level { block["level"] = level }
        return block
    }

    static func table(_ cells: [[String]]) -> JSON {
        var table = block("table", "")
        table["cells"] = cells
        return table
    }

    static func message(_ id: String, _ text: String, user: Bool) -> JSON {
        row(id, text, user ? "message_user" : "message_ai", enabled: false)
    }

    static func reply(_ id: String, _ blocks: [JSON], caption: String = "") -> JSON {
        var reply = row(id, "Omi", "message_ai", subtitle: caption, enabled: false)
        reply["blocks"] = blocks
        return reply
    }

    /// The chat opens loading; its history arrives once it has mounted.
    static func chat() -> JSON {
        var screen = surface("Ask Omi", toolbar: [back(), row("chat_new", "New Chat", "button", symbol: "square.and.pencil")],
                             sections: [section("messages", "", [])])
        screen["loading"] = true
        screen["loadingLabel"] = "Loading…"
        screen["chat"] = ["draft": "", "placeholder": "Ask Omi", "streaming": false,
                          "followup": "What should I prepare for Thursday?",
                          "actions": [row("chat_draft", "Ask Omi", "text", value: ""),
                                      row("chat_send", "Send", "button", symbol: "arrow.up")]]
        return screen
    }

    static func chatHistory() -> [JSON] {
        [
            message("q1", "What did we decide in this morning's product sync?", user: true),
            reply("a1", [
                block("heading", "Weekly product sync", level: 3),
                block("text", "Here is what the team agreed on:"),
                block("text", "Beta invites move to **Thursday**", prefix: "1."),
                block("text", "The cohort grows to about **500 testers**", prefix: "2."),
                block("text", "Bluetooth is requested only when the pendant pairs", prefix: "3."),
                block("heading", "Owners", level: 3),
                table([["Task", "Owner", "Due"], ["Onboarding mocks", "Priya", "Tue"],
                       ["Firmware 3.1 to QA", "Mike", "Wed"], ["Beta email", "Sarah", "Thu"]]),
            ], caption: "From Weekly product sync · Today"),
            message("q2", "Add those to my tasks and remind me to book the dentist follow-up.", user: true),
            message("a2", "Done. I added **3 tasks** and a reminder for **Monday at 9 AM** to book the dentist follow-up.", user: false),
            message("q3", "Draft a short beta announcement in Markdown.", user: true),
            reply("a3", [
                block("text", "Here is a short draft you can paste:"),
                block("code", "## The Omi beta is growing\n500 new testers join Thursday.\nFirmware 3.1 pairs faster\nand lasts 22% longer."),
                block("quote", "Tip: Sarah is drafting the email, so share this with her first."),
            ]),
        ]
    }

    static func answer(to question: String) -> (blocks: [JSON], caption: String, followup: String) {
        if question.localizedCaseInsensitiveContains("book club") {
            return ([block("text", "Book club meets on **Tuesday at 8 PM** at Sarah's place."),
                     block("text", "You're reading chapters 12–15, and it's your turn to bring snacks.")],
                    "From Book club night · Tue", "Remind me on Tuesday afternoon")
        }
        if question.localizedCaseInsensitiveContains("thursday") {
            return ([block("text", "For Thursday's beta invites:"),
                     block("text", "Review Priya's onboarding mocks", prefix: "•"),
                     block("text", "Confirm the 3.1 build passed QA with Mike", prefix: "•"),
                     block("text", "Approve Sarah's announcement email", prefix: "•"),
                     block("text", "Check that all 500 invites are queued", prefix: "•")],
                    "From Weekly product sync · Today", "Add these to my tasks")
        }
        return ([block("text", "Here is what I found in your conversations from this week.")], "", "")
    }
}

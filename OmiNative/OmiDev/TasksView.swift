import SwiftUI

struct TasksView: View {
    @Environment(SeedStore.self) private var store
    @State private var showComposer = false
    @State private var newTask = ""

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.white.opacity(0.45))
                        TextField("Search tasks", text: Bindable(store).taskQuery)
                            .foregroundStyle(.white)
                            .font(.system(size: 16))
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .omiSearchGlass()
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    ForEach(visibleSections) { section in
                        let items = store.tasks(in: section)
                        if !items.isEmpty {
                            HStack {
                                Text(section.rawValue)
                                    .font(.system(size: 12, weight: .semibold))
                                    .tracking(0.6)
                                    .foregroundStyle(.white.opacity(0.38))
                                Spacer()
                                Text("\(items.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.28))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 22)
                            .padding(.bottom, 8)

                            VStack(spacing: 0) {
                                ForEach(Array(items.enumerated()), id: \.element.id) { index, task in
                                    if index > 0 {
                                        Divider().background(.white.opacity(0.08)).padding(.leading, 50)
                                    }
                                    taskRow(task)
                                }
                            }
                            .omiSurface(radius: 18)
                            .padding(.horizontal, 16)
                        }
                    }
                    Color.clear.frame(height: 80)
                }
            }
            .omiScreenBackground()

            Button {
                showComposer = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
            }
            .modifier(GlassFAB())
            .padding(.trailing, 20)
            .padding(.bottom, 12)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("New task", isPresented: $showComposer) {
            TextField("Task", text: $newTask)
            Button("Add") {
                let title = newTask.trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty {
                    store.tasks.insert(TaskItem(id: UUID().uuidString, title: title, completed: false, dueAt: Date(), priority: "medium", conversationId: nil), at: 0)
                }
                newTask = ""
            }
            Button("Cancel", role: .cancel) { newTask = "" }
        }
    }

    private var visibleSections: [TaskSection] {
        store.showCompletedTasks ? [.completed, .today, .tomorrow, .later, .overdue, .noDeadline] : [.today, .tomorrow, .later, .overdue, .noDeadline]
    }

    private func taskRow(_ task: TaskItem) -> some View {
        Button {
            store.toggleTask(task.id)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                TaskMark(completed: task.completed)
                    .frame(width: 22, height: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(task.completed ? Color.white.opacity(0.4) : .white)
                        .strikethrough(task.completed)
                        .multilineTextAlignment(.leading)
                    if let conversationId = task.conversationId, let conversation = store.conversation(id: conversationId) {
                        Text(conversation.title)
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.38))
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }
}

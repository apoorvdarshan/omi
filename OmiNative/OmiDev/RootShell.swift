import SwiftUI

struct RootShell: View {
    @Environment(SeedStore.self) private var store
    @State private var showSettings = false

    var body: some View {
        @Bindable var store = store
        TabView(selection: $store.selectedTab) {
            Tab("Home", systemImage: "house.fill", value: 0) {
                NavigationStack {
                    HomeView()
                        .toolbar { chromeToolbar }
                }
            }
            Tab("Conversations", systemImage: "bubble.left.and.bubble.right.fill", value: 1) {
                NavigationStack {
                    ConversationsView()
                        .toolbar { chromeToolbar }
                }
            }
            Tab("Tasks", systemImage: "checklist", value: 2) {
                NavigationStack {
                    TasksView()
                        .toolbar { chromeToolbar }
                }
            }
            Tab("Apps", systemImage: "puzzlepiece.extension.fill", value: 3) {
                NavigationStack {
                    AppsView()
                        .toolbar { chromeToolbar }
                }
            }
        }
        .tint(.white)
        .modifier(LiquidGlassTabChrome())
        .fullScreenCover(isPresented: $store.isChatPresented) {
            ChatView(autoVoice: store.chatAutoVoice)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
        .onAppear {
            for argument in ProcessInfo.processInfo.arguments {
                if argument.hasPrefix("--tab="), let value = Int(argument.dropFirst(6)) {
                    store.selectedTab = value
                }
                if argument == "--chat" {
                    store.openChat()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var chromeToolbar: some ToolbarContent {
        if store.selectedTab == 2 {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.showCompletedTasks.toggle()
                } label: {
                    Image(systemName: store.showCompletedTasks ? "checkmark.circle.fill" : "checkmark.circle")
                }
                .modifier(GlassToolbarButton())
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
            }
            .modifier(GlassToolbarButton())
        }
    }
}

private struct LiquidGlassTabChrome: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

private struct GlassToolbarButton: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content
        }
    }
}

struct HomeComposerBar: View {
    let isRecording: Bool
    let onAsk: () -> Void
    let onMic: () -> Void
    let onRecord: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Button(action: onAsk) {
                    Text("Ask Omi anything")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                Button(action: onMic) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color(red: 0.11, green: 0.11, blue: 0.13), in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 0.8))

            Button(action: onRecord) {
                Image(systemName: isRecording ? "stop.fill" : "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(isRecording ? Color.red : OmiTheme.purple, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

struct SettingsView: View {
    @Environment(SeedStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    LabeledContent("Name", value: store.userName)
                    LabeledContent("UID", value: "ui-preview")
                    LabeledContent("Language", value: "English")
                }
                Section("Memories") {
                    ForEach(store.memories) { memory in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memory.content)
                                .foregroundStyle(.white)
                            Text(memory.category.uppercased())
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(OmiTheme.muted)
                        }
                    }
                }
                Section("People") {
                    Text("Maya")
                    Text("Arjun")
                    Text("Nina")
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .modifier(GlassToolbarButton())
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

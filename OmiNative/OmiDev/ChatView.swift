import SwiftUI

struct ChatView: View {
    @Environment(SeedStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var autoVoice = false
    @State private var showApps = false

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        ForEach(store.messages) { message in
                            if message.isUser {
                                HStack {
                                    Spacer(minLength: 48)
                                    Text(message.text)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.white)
                                        .lineSpacing(3)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                            } else {
                                Text(message.text)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.92))
                                    .lineSpacing(4)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        Color.clear.frame(height: 8).id("end")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                }
                .onChange(of: store.messages.count) {
                    proxy.scrollTo("end", anchor: .bottom)
                }
            }
            .omiScreenBackground()
            .navigationTitle("Omi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.backward")
                    }
                    .modifier(GlassCircleButton())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showApps = true } label: {
                        Image(systemName: "puzzlepiece.extension")
                    }
                    .modifier(GlassCircleButton())
                }
            }
            .safeAreaInset(edge: .bottom) {
                inputBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showApps) {
            chatApps
        }
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask anything", text: Bindable(store).draft, axis: .vertical)
                .font(.system(size: 16))
                .foregroundStyle(.white)
                .lineLimit(1...5)
                .padding(.leading, 16)
            Button {
                if store.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    store.draft = "What did I talk about at standup?"
                }
                store.sendDraft()
            } label: {
                Image(systemName: store.draft.isEmpty ? "mic.fill" : "arrow.up")
                    .font(.system(size: 15, weight: .semibold))
            }
            .modifier(GlassSendButton(empty: store.draft.isEmpty))
            .padding(.trailing, 6)
        }
        .padding(.vertical, 6)
        .omiGlass(in: Capsule())
    }

    private var chatApps: some View {
        NavigationStack {
            List {
                ForEach(store.apps.filter(\.enabled)) { app in
                    HStack {
                        Text(app.emoji)
                        Text(app.name)
                    }
                }
            }
            .navigationTitle("Chat apps")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showApps = false }
                }
            }
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

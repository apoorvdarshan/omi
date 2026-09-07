import SwiftUI

struct ConversationDetailView: View {
    let conversation: Conversation
    @State private var tab = 1

    var body: some View {
        ZStack {
            OmiTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Picker("", selection: $tab) {
                    Text("Transcript").tag(0)
                    Text("Summary").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(16)

                if tab == 0 {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(conversation.transcript) { line in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(line.speaker)
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(OmiTheme.muted)
                                    Text(line.text)
                                        .font(.system(size: 15))
                                        .foregroundStyle(Color.gray.opacity(0.85))
                                        .lineSpacing(3)
                                }
                            }
                        }
                        .padding(20)
                    }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 12) {
                                Text(conversation.emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(OmiTheme.tertiary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(conversation.title)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text("\(conversation.startedAt.timeLabel) · \(conversation.minutes)m · \(conversation.category)")
                                        .font(.system(size: 13))
                                        .foregroundStyle(OmiTheme.meta)
                                }
                            }
                            Text(conversation.overview)
                                .font(.system(size: 15))
                                .foregroundStyle(Color.gray.opacity(0.85))
                                .lineSpacing(4)
                            if !conversation.actions.isEmpty {
                                Text("Action items")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.top, 8)
                                ForEach(conversation.actions, id: \.self) { action in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle().stroke(Color.gray.opacity(0.55), lineWidth: 1.5).frame(width: 18, height: 18)
                                        Text(action)
                                            .font(.system(size: 15))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Image(systemName: conversation.starred ? "star.fill" : "star")
                        .foregroundStyle(conversation.starred ? OmiTheme.amber : .white.opacity(0.7))
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct DailyRecapDetailView: View {
    let recap: DailyRecap

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                LinearGradient(colors: [OmiTheme.recapHero, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                    .overlay(alignment: .bottomLeading) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(recap.date.recapLabel)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                            HStack {
                                Text(recap.emoji).font(.system(size: 32))
                                Text(recap.headline)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(20)
                    }
                Text(recap.overview)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.gray.opacity(0.85))
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
                stats
                if !recap.highlights.isEmpty {
                    card(title: "Highlights") {
                        ForEach(recap.highlights) { highlight in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("\(highlight.emoji)  \(highlight.topic)")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(highlight.summary)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.gray.opacity(0.8))
                            }
                        }
                    }
                }
                if !recap.actions.isEmpty {
                    card(title: "Action items") {
                        ForEach(recap.actions, id: \.self) { action in
                            Text("•  \(action)")
                                .font(.system(size: 15))
                                .foregroundStyle(.white)
                        }
                    }
                }
                Color.clear.frame(height: 40)
            }
        }
        .omiScreenBackground()
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var stats: some View {
        HStack {
            stat("\(recap.conversationCount)", "convos")
            stat("\(recap.durationMinutes)m", "time")
            stat("\(recap.actionCount)", "tasks")
        }
        .padding(.horizontal, 20)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
            Text(label).font(.system(size: 12)).foregroundStyle(OmiTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .omiSurface(radius: 16)
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .omiSurface(radius: 16)
        .padding(.horizontal, 20)
    }
}

struct AppDetailView: View {
    let app: OmiAppItem
    @Environment(SeedStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    Text(app.emoji)
                        .font(.system(size: 40))
                        .frame(width: 72, height: 72)
                        .background(OmiTheme.tertiary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("\(app.author) · \(app.category)")
                            .font(.system(size: 14))
                            .foregroundStyle(OmiTheme.muted)
                        Text(String(format: "%.1f · %d ratings", app.rating, app.ratingCount))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gray)
                    }
                }
                Text(app.description)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineSpacing(4)
                AppActionButton(
                    title: store.apps.first { $0.id == app.id }?.enabled == true ? "Open" : "Enable",
                    enabledLook: store.apps.first { $0.id == app.id }?.enabled == true,
                    prominent: true
                ) {
                    store.toggleApp(app.id)
                }
                if app.official {
                    Text("Official Omi app")
                        .font(.system(size: 13))
                        .foregroundStyle(OmiTheme.muted)
                }
            }
            .padding(20)
        }
        .omiScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

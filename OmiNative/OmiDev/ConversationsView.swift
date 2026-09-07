import SwiftUI

struct ConversationsView: View {
    @Environment(SeedStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                searchField
                filterChips
                if store.showDailyRecaps {
                    recapList
                } else {
                    goals
                    conversationList
                }
            }
            .padding(.bottom, 16)
        }
        .omiScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white.opacity(0.45))
            TextField("Search conversations", text: Bindable(store).conversationQuery)
                .foregroundStyle(.white)
                .font(.system(size: 16))
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .omiSearchGlass()
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var filterChips: some View {
        HStack(spacing: 8) {
            chip("All", selected: !store.showStarredOnly && !store.showDailyRecaps) {
                store.showStarredOnly = false
                store.showDailyRecaps = false
            }
            chip("Starred", selected: store.showStarredOnly) {
                store.showStarredOnly.toggle()
                store.showDailyRecaps = false
            }
            chip("Recaps", selected: store.showDailyRecaps) {
                store.showDailyRecaps.toggle()
                store.showStarredOnly = false
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 14, weight: selected ? .semibold : .medium))
            .foregroundStyle(selected && title == "Starred" ? OmiTheme.amber : selected ? .white : .white.opacity(0.5))
            .modifier(GlassChipButton())
            .tint(selected && title == "Starred" ? OmiTheme.amber : .white)
    }

    private var goals: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Goals")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 10)
            VStack(spacing: 14) {
                ForEach(store.goals) { goal in
                    HStack(spacing: 12) {
                        Text(goal.emoji)
                            .font(.system(size: 18))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(goal.title)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            GeometryReader { geo in
                                Capsule().fill(Color.white.opacity(0.12))
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(OmiTheme.green)
                                            .frame(width: geo.size.width * CGFloat(goal.current / max(goal.target, 1)))
                                    }
                            }
                            .frame(height: 5)
                        }
                        Text("\(Int(goal.current))/\(Int(goal.target))")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            }
            .padding(14)
            .omiSurface(radius: 20)
            .padding(.horizontal, 16)
        }
    }

    private var conversationList: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Conversations")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 10)
            ForEach(store.groupedConversations, id: \.0) { day, items in
                if let header = day.dayHeader {
                    Text(header)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 6)
                }
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, conversation in
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
                .padding(.bottom, 10)
            }
        }
    }

    private var recapList: some View {
        VStack(spacing: 12) {
            ForEach(store.recaps) { recap in
                NavigationLink {
                    DailyRecapDetailView(recap: recap)
                } label: {
                    HStack(spacing: 12) {
                        Text(recap.emoji)
                            .font(.system(size: 24))
                            .frame(width: 44, height: 44)
                            .background(OmiTheme.recapHero.opacity(0.7), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(recap.headline)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white)
                            Text("\(recap.date.recapLabel) · \(recap.conversationCount) convos · \(recap.durationMinutes)m")
                                .font(.system(size: 13))
                                .foregroundStyle(OmiTheme.meta)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .omiSurface(radius: 18)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }
}

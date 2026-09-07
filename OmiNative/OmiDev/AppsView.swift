import SwiftUI

struct AppsView: View {
    @Environment(SeedStore.self) private var store

    private var groups: [(String, [OmiAppItem])] {
        let filtered = store.apps.filter {
            store.appQuery.isEmpty || $0.name.localizedCaseInsensitiveContains(store.appQuery) || $0.category.localizedCaseInsensitiveContains(store.appQuery)
        }
        let order = ["Productivity", "Health", "Lifestyle"]
        return order.compactMap { category in
            let items = filtered.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.45))
                    TextField("Search apps", text: Bindable(store).appQuery)
                        .foregroundStyle(.white)
                        .font(.system(size: 16))
                }
                .padding(.horizontal, 14)
                .frame(height: 44)
                .omiSearchGlass()
                .padding(.horizontal, 16)
                .padding(.top, 4)

                ForEach(groups, id: \.0) { category, apps in
                    Text(category)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 10)

                    VStack(spacing: 0) {
                        ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                            if index > 0 {
                                Divider().background(.white.opacity(0.08)).padding(.leading, 86)
                            }
                            NavigationLink {
                                AppDetailView(app: app)
                            } label: {
                                appRow(app)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .omiSurface(radius: 20)
                    .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 16)
        }
        .omiScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private func appRow(_ app: OmiAppItem) -> some View {
        HStack(spacing: 12) {
            Text(app.emoji)
                .font(.system(size: 26))
                .frame(width: 52, height: 52)
                .background(OmiTheme.tertiary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 3) {
                Text(app.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text("\(app.category) · \(String(format: "%.1f", app.rating))")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer(minLength: 8)
            AppActionButton(title: app.enabled ? "Open" : "Enable", enabledLook: app.enabled) {
                store.toggleApp(app.id)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}

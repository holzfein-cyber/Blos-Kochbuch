import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Blos Kochbuch")
                    .font(.largeTitle)
                    .bold()

                Text("Wähle aus, was du machen möchtest:")
                    .foregroundStyle(.secondary)

                NavigationLink {
                    CategoryListView()
                } label: {
                    Label("Zu den Rezepten", systemImage: "fork.knife")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                NavigationLink {
                    CalorieCalculatorView()
                } label: {
                    Label("Zum Kalorienbedarfsrechner", systemImage: "flame")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                NavigationLink {
                    DailyTrackerView()
                } label: {
                    Label("Zum Tagestrecker", systemImage: "calendar")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
            .padding()
        }
    }
}


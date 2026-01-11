import SwiftUI

struct StartView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 34, weight: .semibold))
                    Text("Blos Kochbuch")
                        .font(.title)
                        .bold()
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color(red: 0.98, green: 0.67, blue: 0.60))
                )
                .foregroundStyle(.white)

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

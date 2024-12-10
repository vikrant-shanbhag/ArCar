import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    NavigationLink(destination: ProductCategoriesView()) {
                        MainMenuTile(title: "Products", gradientColors: [.blue, .cyan], icon: "cart.fill")
                    }
                    MainMenuTile(title: "Customer Analytics", gradientColors: [.green, .teal], icon: "person.2.fill")
                    MainMenuTile(title: "Inventory Management", gradientColors: [.orange, .yellow], icon: "archivebox.fill")
                    MainMenuTile(title: "Update Catalog", gradientColors: [.purple, .pink], icon: "square.and.pencil")
                    MainMenuTile(title: "Sales Analytics", gradientColors: [.red, .mint], icon: "chart.bar.fill")
                    MainMenuTile(title: "Promote", gradientColors: [.indigo, .red], icon: "megaphone.fill")
                    MainMenuTile(title: "Demo", gradientColors: [.gray, .black], icon: "play.rectangle.fill")
                    MainMenuTile(title: "Invoicing", gradientColors: [.brown, .yellow], icon: "doc.text.fill")
                }
                .padding()
            }
            .navigationTitle("Main Menu")
        }
    }
}

struct MainMenuTile: View {
    let title: String
    let gradientColors: [Color]
    let icon: String

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)

            VStack {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(height: 120)
    }
}

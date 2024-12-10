import SwiftUI

struct ProductCategoriesView: View {
    @State private var categories: [Product] = []
    @State private var searchText: String = ""

    var body: some View {
        VStack {
            SearchBar(text: $searchText)
                .padding()

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(filteredCategories(), id: \.id) { category in
                        NavigationLink(destination: SubCategoryView(categoryName: category.name)) {
                            ProductTile(product: category)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Product Categories")
        .onAppear(perform: loadCategories)
    }

    private func filteredCategories() -> [Product] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadCategories() {
        categories = [
            Product(name: "Wheels", gradientColors: [.blue, .cyan], usdzFileName: "", icon: "circle.grid.3x3.fill"),
            Product(name: "Spoilers", gradientColors: [.green, .teal], usdzFileName: "", icon: "car.fill"),
            Product(name: "Custom Vinyl", gradientColors: [.purple, .pink], usdzFileName: "", icon: "paintbrush.fill"),
            Product(name: "Exhaust", gradientColors: [.orange, .yellow], usdzFileName: "", icon: "cloud.fill")
        ]
    }
}

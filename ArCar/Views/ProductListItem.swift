import SwiftUI

struct ProductListItem: View {
    let product: Product

    var body: some View {
        HStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: product.gradientColors),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 60, height: 60)
                .cornerRadius(10)
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)

                Image(systemName: product.icon)
                    .font(.title2)
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Details about \(product.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 5)
    }
}

import SwiftUI

struct ProductTile: View {
    let product: Product

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: product.gradientColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(10)

            VStack {
                Image(systemName: product.icon)
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding()
        }
        .frame(height: 120)
    }
}

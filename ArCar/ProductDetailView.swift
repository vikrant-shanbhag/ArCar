import SwiftUI

struct ProductDetailView: View {
    let product: Product

    var body: some View {
        VStack {
            Text(product.name)
                .font(.largeTitle)
                .padding()

            QuickLookPreviewControllerWrapper(usdzFileName: product.usdzFileName)
                .frame(height: 300) // Ensure frame is applied on the wrapper, not the UIViewController directly.
        }
        .navigationTitle(product.name)
    }
}

// Wrapper to use QuickLookPreviewController with SwiftUI
struct QuickLookPreviewControllerWrapper: UIViewControllerRepresentable {
    let usdzFileName: String

    func makeUIViewController(context: Context) -> QuickLookPreviewController {
        return QuickLookPreviewController(usdzFileName: usdzFileName)
    }

    func updateUIViewController(_ uiViewController: QuickLookPreviewController, context: Context) {
        // Update the controller if needed
    }
}

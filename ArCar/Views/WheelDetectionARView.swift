import SwiftUI

struct WheelDetectionARView: UIViewControllerRepresentable {
    let usdzFilePath: String

    func makeUIViewController(context: Context) -> ARSCNViewController {
        let viewController = ARSCNViewController()
        print("USDZ File Path Passed: \(usdzFilePath)") //
        viewController.usdzFilePath = usdzFilePath
        return viewController
    }

    func updateUIViewController(_ uiViewController: ARSCNViewController, context: Context) {
        // No updates required in this implementation
    }
}

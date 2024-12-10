import SwiftUI
import QuickLook

struct ARViewController: UIViewControllerRepresentable {
    let usdzFileName: String

    func makeUIViewController(context: Context) -> QLPreviewController {
        let previewController = QLPreviewController()
        previewController.dataSource = context.coordinator
        return previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(usdzFileName: usdzFileName)
    }

    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let usdzFileName: String

        init(usdzFileName: String) {
            self.usdzFileName = usdzFileName
        }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
            return 1
        }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            let url = Bundle.main.url(forResource: usdzFileName, withExtension: "")!
            return url as QLPreviewItem
        }
    }
}

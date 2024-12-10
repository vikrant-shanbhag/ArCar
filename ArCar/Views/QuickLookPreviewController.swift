import UIKit
import QuickLook

class QuickLookPreviewController: QLPreviewController, QLPreviewControllerDataSource {
    private var usdzFileName: String

    init(usdzFileName: String) {
        self.usdzFileName = usdzFileName
        super.init(nibName: nil, bundle: nil)
        self.dataSource = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }

    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        guard let fileURL = Bundle.main.url(forResource: usdzFileName, withExtension: "") else {
            fatalError("USDZ file not found: \(usdzFileName)")
        }
        return fileURL as QLPreviewItem
    }
}

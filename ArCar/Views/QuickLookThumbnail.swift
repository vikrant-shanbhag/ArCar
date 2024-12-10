import SwiftUI
import QuickLookThumbnailing

struct QuickLookThumbnail: View {
    let usdzFileURL: URL

    @State private var thumbnailImage: UIImage?

    var body: some View {
        Group {
            if let thumbnailImage = thumbnailImage {
                Image(uiImage: thumbnailImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Rectangle()
                    .fill(Color.gray)
                    .overlay(ProgressView())
            }
        }
        .onAppear(perform: generateThumbnail)
    }

    private func generateThumbnail() {
        let request = QLThumbnailGenerator.Request(
            fileAt: usdzFileURL,
            size: CGSize(width: 120, height: 120),
            scale: UIScreen.main.scale,
            representationTypes: .thumbnail
        )

        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnail, _, error in
            if let thumbnail = thumbnail {
                DispatchQueue.main.async {
                    self.thumbnailImage = thumbnail.uiImage
                }
            } else {
                print("Error generating thumbnail for \(usdzFileURL): \(String(describing: error))")
            }
        }
    }
}

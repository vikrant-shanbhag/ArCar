import SwiftUI

struct SubCategoryView: View {
    let categoryName: String
    @State private var files: [Product] = []
    @State private var isGrid: Bool = true

    var body: some View {
        VStack {
            // Toggle between grid and list views
            ListOrGridToggle(isGridView: $isGrid)
                .padding(.horizontal)

            // Check view type and display files
            if !isGrid {
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(files) { file in
                            Button(action: {
                                open3DViewer(for: file.usdzFileName)
                            }) {
                                ProductListItem(product: file)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(files) { file in
                            Button(action: {
                                open3DViewer(for: file.usdzFileName)
                            }) {
                                ProductTile(product: file)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .top) // Align grid to the top
                }
            }
        }
        .navigationTitle(categoryName)
        .onAppear(perform: loadFiles)
    }

    private func loadFiles() {
        let fileManager = FileManager.default
        var categoryPath = ""

        // Map category names to folder paths in USDZAssets
        switch categoryName {
        case "Wheels":
            categoryPath = "/USDZAssets/Wheels"
        case "Spoilers":
            categoryPath = "/USDZAssets/Spoiler"
        case "Custom Vinyl":
            categoryPath = "/USDZAssets/CustomVinyl"
        default:
            print("Unknown category: \(categoryName)")
            return
        }

        guard let fullPath = Bundle.main.resourcePath?.appending(categoryPath) else {
            print("Error: \(categoryPath) folder not found in bundle")
            return
        }

        print("Resolved Category Path: \(fullPath)")

        var loadedFiles: [Product] = []

        do {
            let files = try fileManager.contentsOfDirectory(atPath: fullPath)
            print("Files in \(categoryName): \(files)") // Debugging: List all files

            for file in files where file.hasSuffix(".usdz") {
                let fileName = file//.replacingOccurrences(of: ".usdz", with: "")
                let newFile = Product(
                    name: fileName,
                    gradientColors: [.green, .blue],
                    usdzFileName: "\(categoryPath)/\(file)",
                    icon: "cube"
                )
                loadedFiles.append(newFile)
            }
        } catch {
            print("Error: Could not list files in \(categoryName): \(error.localizedDescription)")
        }

        // Update the state to refresh the view
        DispatchQueue.main.async {
            self.files = loadedFiles
        }
    }

    private func open3DViewer(for usdzFileName: String) {
        // Present WheelDetectionARView instead of QuickLookPreviewController
        let arView = WheelDetectionARView(usdzFilePath: usdzFileName)
        if let window = UIApplication.shared.windows.first {
            window.rootViewController?.present(UIHostingController(rootView: arView), animated: true, completion: nil)
        }
    }
}

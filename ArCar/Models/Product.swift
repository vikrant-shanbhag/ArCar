import SwiftUI

struct Product: Identifiable {
    let id = UUID()
    let name: String
    let gradientColors: [Color]
    let usdzFileName: String
    let icon: String
}

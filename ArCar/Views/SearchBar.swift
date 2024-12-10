import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        TextField("Search...", text: $text)
            .padding(10)
            .background(Color(.systemGray5))
            .cornerRadius(10)
            .padding(.horizontal)
    }
}

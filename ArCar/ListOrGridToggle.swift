import SwiftUI

struct ListOrGridToggle: View {
    @Binding var isGridView: Bool

    var body: some View {
        HStack {
            Spacer()

            Button(action: {
                isGridView = true
            }) {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundColor(isGridView ? .blue : .gray)
            }

            Button(action: {
                isGridView = false
            }) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .foregroundColor(isGridView ? .gray : .blue)
            }
            .padding(.leading)
        }
    }
}

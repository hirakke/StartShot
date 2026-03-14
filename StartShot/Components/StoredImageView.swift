import SwiftUI
import UIKit

struct StoredImageView: View {
    let relativePath: String?
    let emptyText: String
    var height: CGFloat = 180

    var body: some View {
        Group {
            if let relativePath, let image = PhotoFileStore.image(for: relativePath) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.secondary.opacity(0.12))
                    Text(emptyText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

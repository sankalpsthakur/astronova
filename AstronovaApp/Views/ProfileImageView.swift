import SwiftUI

struct ProfileImageView: View {
    let imageURL: String?
    let size: CGFloat
    let fallbackIcon: String
    
    init(imageURL: String?, size: CGFloat = 60, fallbackIcon: String = "person.crop.circle.fill") {
        self.imageURL = imageURL
        self.size = size
        self.fallbackIcon = fallbackIcon
    }
    
    var body: some View {
        Group {
            if let imageURL = imageURL, let url = URL(string: imageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: fallbackIcon)
                                .foregroundStyle(.gray)
                                .font(.system(size: size * 0.4))
                        )
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(.blue.opacity(0.2))
                    .overlay(
                        Image(systemName: fallbackIcon)
                            .foregroundStyle(.blue)
                            .font(.system(size: size * 0.4))
                    )
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(imageURL != nil ? "User profile picture" : "Default profile picture")
        .accessibilityAddTraits(.isImage)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProfileImageView(imageURL: nil, size: 80)
        ProfileImageView(imageURL: "https://example.com/avatar.jpg", size: 60)
        ProfileImageView(imageURL: nil, size: 40, fallbackIcon: "star.fill")
    }
    .padding()
}
import SwiftUI

struct CardBadgeView: View {
    let status: CardStatus

    var body: some View {
        switch status {
        case .none:
            EmptyView()
        case .yellow:
            badge(color: .yellow, label: "Y")
        case .black:
            badge(color: .black, label: "B")
        case .red:
            badge(color: .red, label: "R")
        }
    }

    private func badge(color: Color, label: String) -> some View {
        Text(label)
            .font(.caption2.bold())
            .foregroundStyle(.white)
            .frame(width: 16, height: 20)
            .background(color)
            .cornerRadius(2)
    }
}

struct CrestOrInitialsView: View {
    let crestData: Data?
    let shortName: String
    let colourHex: String
    var size: CGFloat = 32

    var body: some View {
        if let data = crestData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.15)
                    .fill(Color(hex: colourHex))
                    .frame(width: size, height: size)
                Text(String(shortName.prefix(1)))
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

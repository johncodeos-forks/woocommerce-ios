import SwiftUI

/// Renders a row with a label on the left side, and a text field on the right side, with eventually a symbol (like $)
///
struct TitleAndTextFieldRow: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let symbol: String?
    let keyboardType: UIKeyboardType
    let onEditingChanged: ((Bool) -> Void)?

    init(title: String,
         placeholder: String,
         text: Binding<String>,
         symbol: String? = nil,
         keyboardType: UIKeyboardType = .default,
         onEditingChanged: ((Bool) -> Void)? = nil) {
        self.title = title
        self.placeholder = placeholder
        self._text = text
        self.symbol = symbol
        self.keyboardType = keyboardType
        self.onEditingChanged = onEditingChanged
    }

    var body: some View {
        AdaptiveStack(horizontalAlignment: .leading) {
            Text(title)
                .bodyStyle()
                .lineLimit(1)
                .fixedSize()
            HStack {
                TextField(placeholder, text: $text, onEditingChanged: onEditingChanged ?? { _ in })
                    .multilineTextAlignment(.trailing)
                    .font(.body)
                    .keyboardType(keyboardType)
                if let symbol = symbol {
                    Text(symbol)
                        .bodyStyle()
                }
            }
        }
        .frame(minHeight: Constants.height)
        .padding([.leading, .trailing], Constants.padding)
    }
}

private extension TitleAndTextFieldRow {
    enum Constants {
        static let height: CGFloat = 44
        static let padding: CGFloat = 16
    }
}

struct TitleAndTextFieldRow_Previews: PreviewProvider {
    static var previews: some View {
        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant(""),
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("No text")

        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant("Hello"),
                             symbol: nil,
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With text")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: .constant(""),
                             symbol: "oz",
                             keyboardType: .default)
            .previewLayout(.fixed(width: 375, height: 100))
            .previewDisplayName("With symbol")

        TitleAndTextFieldRow(title: "Add your text",
                             placeholder: "Start typing",
                             text: .constant("Hello"),
                             symbol: nil,
                             keyboardType: .default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Dynamic Type: Large Font Size")

        TitleAndTextFieldRow(title: "Total package weight",
                             placeholder: "Value",
                             text: .constant(""),
                             symbol: "oz",
                             keyboardType: .default)
            .environment(\.sizeCategory, .accessibilityExtraLarge)
            .previewLayout(.fixed(width: 375, height: 150))
            .previewDisplayName("Dynamic Type: Large Font Size with symbol")
    }
}

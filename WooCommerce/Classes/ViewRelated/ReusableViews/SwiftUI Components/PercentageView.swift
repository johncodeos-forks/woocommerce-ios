import SwiftUI

// MARK: - PercetageView
//
struct PercentageView: View {
    var bgColor: UIColor
    var percentageTextColor: UIColor
    var percentageValue: String
    var body: some View {
        ZStack(alignment: .center, content: {
            Text(percentageValue)
                .font(Font.system(size: 12))
                .foregroundColor(Color(percentageTextColor))
                .padding(EdgeInsets(top: 3, leading: 7, bottom: 3, trailing: 7))
                .background(RoundedRectangle(cornerRadius: 4).foregroundColor(Color(bgColor)))
        })
    }
}

struct PercetageView_Previews: PreviewProvider {
    static var previews: some View {
                            PercentageView(bgColor: .percentagePositive, percentageTextColor: .white, percentageValue: "-23%")
    }
}

#if DEBUG
import SwiftUI

struct ReportPreviewGalleryView: View {
    private let summaries = ReportSummary.previewSamples

    var body: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 24) {
                ForEach(Array(summaries.enumerated()), id: \.offset) { index, summary in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Random Report \(index + 1)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        ReportView(
                            onHome: {},
                            summary: summary
                        )
                        .frame(width: 393, height: 852)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .overlay {
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(Color(.systemGroupedBackground))
    }
}

#Preview("Report Random 10") {
    ReportPreviewGalleryView()
}
#endif

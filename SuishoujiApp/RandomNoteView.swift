import SwiftUI

/// 随机回顾——展示一条随机旧记录
struct RandomNoteView: View {
    let note: Note
    @Environment(\.dismiss) private var dismiss

    private static let quotes = [
        "时光流过，你留住了它。",
        "每一刻，都值得被记住。",
        "这一天，已成永恒。",
        "记下来，才真正拥有。",
        "回头看，才知道走了多远。",
        "生活不会重来，幸好你记下了。",
        "此刻的你，正在和过去的你相遇。",
        "有些美好，只有自己才懂。",
        "岁月无痕，你却留下了印记。",
        "那一天，风吹过，你在。",
    ]
    private let quote = quotes.randomElement()!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 日期
                    Text(note.timestamp, style: .date)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // 图片/视频
                    if let data = note.photoData, let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .clipped()
                            .cornerRadius(16)
                            .padding(.horizontal)
                    } else if let videoURL = note.videoURLs.first {
                        VideoThumbnailView(videoURL: videoURL)
                            .frame(maxWidth: .infinity)
                            .frame(height: 240)
                            .cornerRadius(16)
                            .padding(.horizontal)
                    }

                    // 文字
                    if !note.text.isEmpty {
                        Text(note.text)
                            .font(.body)
                            .padding(.horizontal)
                    }

                    // 位置
                    if let loc = note.locationName {
                        Label(loc, systemImage: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }

                    // 标签
                    if let tags = note.tags, !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 12))
                                        .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.83))
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Color(red: 0.55, green: 0.22, blue: 0.83).opacity(0.1), in: Capsule())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                // 文艺文案
                VStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.horizontal, 40)
                    Text(quote)
                        .font(.system(size: 14, weight: .light))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .navigationTitle("随手回顾")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}

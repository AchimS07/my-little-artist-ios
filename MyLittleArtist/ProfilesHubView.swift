import SwiftUI
import SwiftData

struct ProfilesHubView: View {
    var profiles: [UserProfile]
    var onPick: (UserProfile) -> Void
    var onAdd: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 48))
                    .symbolRenderingMode(.multicolor)
                Text("Who's Drawing Today?")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.heavy)
                Text("Tap your profile to start! 👆")
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 40)

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(profiles) { p in
                        Button {
                            onPick(p)
                        } label: {
                            HStack(spacing: 16) {
                                Text(p.avatarEmoji ?? "🧒")
                                    .font(.system(size: 36))
                                    .frame(width: 56, height: 56)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(p.name.isEmpty ? "Unnamed" : p.name)
                                        .font(.headline)
                                    Text("\(p.age) years old")
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
                        }
                        .buttonStyle(.plain)
                    }

                    Button(action: onAdd) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add New Artist")
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .foregroundStyle(.secondary)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal)
            }
        }
        .background(
            LinearGradient(colors: [Color(red: 1.0, green: 0.95, blue: 0.85), Color(red: 0.9, green: 0.95, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}


import SwiftUI
import SwiftData

struct CreateProfileView: View {
    var onCreate: (UserProfile) -> Void
    var onBack: () -> Void

    @State private var name: String = ""
    @State private var age: Int = 6
    @State private var avatar: String = "🦁"

    @AppStorage("appLanguage") private var appLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"
    @AppStorage("profileName") private var storedProfileName: String = ""

    private let avatars = ["🦁","🐰","🦊","🐼","🦄","🐶","🐱","🦋","🐸","🐻"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: onBack) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "back_to_profiles"))
                    }
                }
                .padding(.top)

                Text(String(localized: "create_profile_title"))
                    .font(.system(.largeTitle, design: .rounded)).bold()
                Text(String(localized: "create_profile_subtitle"))
                    .foregroundStyle(.secondary)

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "whats_your_name"))
                            .font(.headline)
                        TextField(String(localized: "enter_name_placeholder"), text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "choose_language"))
                            .font(.headline)
                        Picker(String(localized: "language_picker_label"), selection: $appLanguage) {
                            Text(String(localized: "language_english")).tag("en")
                            Text(String(localized: "language_romanian")).tag("ro")
                        }
                        .pickerStyle(.segmented)
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "how_old_are_you"))
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(3...12, id: \.self) { n in
                                Button {
                                    age = n
                                } label: {
                                    VStack {
                                        Text(ageEmoji(n))
                                        Text("\(n)")
                                    }
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(age == n ? Color.orange.opacity(0.25) : Color.secondary.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(String(localized: "pick_your_buddy"))
                            .font(.headline)
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                            ForEach(avatars, id: \.self) { emo in
                                Button {
                                    avatar = emo
                                } label: {
                                    Text(emo)
                                        .font(.system(size: 28))
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(avatar == emo ? Color.purple.opacity(0.25) : Color.secondary.opacity(0.08))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Button {
                    let profile = UserProfile(id: UUID(), name: name.trimmingCharacters(in: .whitespacesAndNewlines), age: age)
                    profile.avatarEmoji = avatar
                    storedProfileName = profile.name
                    onCreate(profile)
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(String(localized: "lets_draw_button"))
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? Color.accentColor : Color.gray.opacity(0.4))
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.vertical)
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [Color(red: 0.98, green: 0.95, blue: 1.0), Color(red: 0.92, green: 0.98, blue: 0.95)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }

    private func ageEmoji(_ n: Int) -> String {
        switch n {
        case 3,4: return "👶"
        case 5,6: return "🧒"
        case 7,8: return "👦"
        case 9,10: return "👧"
        default: return "⭐"
        }
    }
}

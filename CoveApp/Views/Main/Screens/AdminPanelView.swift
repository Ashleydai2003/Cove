import SwiftUI

struct AdminPanelView: View {
    @StateObject private var adminModel = AdminModel()
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab: AdminTab = .users
    @State private var selectedUserId: String?
    @State private var showingUserDetails = false
    @State private var showingUnmatchedUsersPage = false
    
    enum AdminTab: String, CaseIterable {
        case users = "users"
        case matches = "matches"
    }
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20))
                            .foregroundColor(Colors.primaryDark)
                    }
                    
                    Spacer()
                    
                    Text("admin panel")
                        .font(.LibreBodoniSemiBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Button(action: {
                        if selectedTab == .users {
                            adminModel.fetchUsers(refresh: true)
                        } else {
                            adminModel.fetchMatches(refresh: true)
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(Colors.primaryDark)
                    }
                    .disabled(adminModel.isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(Colors.background)
                
                // Tab Bar
                HStack(spacing: 0) {
                    ForEach(AdminTab.allCases, id: \.self) { tab in
                        Button(action: {
                            selectedTab = tab
                        }) {
                            VStack(spacing: 8) {
                                Text(tab.rawValue)
                                    .font(Fonts.libreBodoni(size: 16))
                                    .foregroundColor(selectedTab == tab ? Colors.primaryDark : Colors.primaryDark.opacity(0.4))
                                
                                Rectangle()
                                    .fill(selectedTab == tab ? Colors.primaryDark : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .background(Colors.background)
                
                // Content
                if selectedTab == .users {
                    usersContent
                } else {
                    matchesContent
                }
            }
        }
        .sheet(isPresented: $showingUserDetails) {
            if let userId = selectedUserId {
                UserDetailsSheet(userId: userId, adminModel: adminModel)
            }
        }
        .fullScreenCover(isPresented: $showingUnmatchedUsersPage) {
            UnmatchedUsersPage(adminModel: adminModel)
        }
        .onAppear {
            adminModel.fetchUsers()
        }
    }
    
    // MARK: - Users Content
    
    @ViewBuilder
    private var usersContent: some View {
        if adminModel.isLoading && adminModel.users.isEmpty {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("loading users...")
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
            }
            .frame(maxHeight: .infinity)
        } else if let errorMessage = adminModel.errorMessage {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.7))
                Text(errorMessage)
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    adminModel.fetchUsers(refresh: true)
                }) {
                    Text("retry")
                        .font(Fonts.libreBodoni(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Colors.primaryDark)
                        .cornerRadius(8)
                }
            }
            .frame(maxHeight: .infinity)
        } else if adminModel.users.isEmpty {
            VStack {
                Text("no users found")
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
            }
            .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(adminModel.users) { user in
                        UserCard(user: user, adminModel: adminModel)
                            .onAppear {
                                // Load more when reaching the last item
                                let currentIndex = adminModel.users.firstIndex(where: { $0.id == user.id }) ?? 0
                                let lastIndex = adminModel.users.count - 1
                                
                                if currentIndex == lastIndex && adminModel.hasMoreUsers && !adminModel.isLoading {
                                    adminModel.fetchUsers()
                                }
                            }
                    }
                    
                    // Loading indicator at the bottom
                    if adminModel.isLoading && !adminModel.users.isEmpty {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Colors.background)
        }
    }
    
    // MARK: - Matches Content
    
    @ViewBuilder
    private var matchesContent: some View {
        VStack(spacing: 0) {
            // Unmatched Users Button
            Button(action: {
                showingUnmatchedUsersPage = true
            }) {
                HStack {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 16))
                    Text("view unmatched users in pool")
                        .font(Fonts.libreBodoni(size: 14))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Colors.primaryDark)
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            // Matches List
            matchesListContent
        }
    }
    
    @ViewBuilder
    private var matchesListContent: some View {
        if adminModel.isLoading && adminModel.matches.isEmpty {
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("loading matches...")
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
            }
            .frame(maxHeight: .infinity)
        } else if let errorMessage = adminModel.errorMessage {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.7))
                Text(errorMessage)
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Button(action: {
                    adminModel.fetchMatches(refresh: true)
                }) {
                    Text("retry")
                        .font(Fonts.libreBodoni(size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Colors.primaryDark)
                        .cornerRadius(8)
                }
            }
            .frame(maxHeight: .infinity)
        } else if adminModel.matches.isEmpty {
            VStack {
                Text("no matches found")
                    .font(Fonts.libreBodoni(size: 16))
                    .foregroundColor(Colors.primaryDark.opacity(0.7))
            }
            .frame(maxHeight: .infinity)
            .onAppear {
                adminModel.fetchMatches()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(adminModel.matches) { match in
                        MatchCard(
                            match: match,
                            onMemberTap: { userId in
                                selectedUserId = userId
                                showingUserDetails = true
                            }
                        )
                        .onAppear {
                            // Load more when reaching the last item
                            let currentIndex = adminModel.matches.firstIndex(where: { $0.id == match.id }) ?? 0
                            let lastIndex = adminModel.matches.count - 1
                            
                            if currentIndex == lastIndex && adminModel.hasMoreMatches && !adminModel.isLoading {
                                adminModel.fetchMatches()
                            }
                        }
                    }
                    
                    // Loading indicator at the bottom
                    if adminModel.isLoading && !adminModel.matches.isEmpty {
                        ProgressView()
                            .padding()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Colors.background)
        }
    }
}

// MARK: - Match Card

private struct MatchCard: View {
    let match: AdminMatch
    let onMemberTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("group of \(match.groupSize)")
                    .font(.LibreBodoniSemiBold(size: 18))
                    .foregroundColor(Colors.primaryDark)
                
                Spacer()
                
                Text(match.status)
                    .font(.LibreBodoniItalic(size: 12))
                    .foregroundColor(statusColor(for: match.status))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(statusColor(for: match.status).opacity(0.15))
                    .cornerRadius(12)
            }
            
            HStack(spacing: 16) {
                if let score = match.score {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("match score")
                            .font(.LibreBodoniItalic(size: 11))
                            .foregroundColor(Colors.primaryDark.opacity(0.6))
                        Text(match.formattedScore)
                            .font(.LibreBodoniSemiBold(size: 16))
                            .foregroundColor(scoreColor(for: score))
                    }
                }
                
                if let tierUsed = match.tierUsed {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("tier")
                            .font(.LibreBodoniItalic(size: 11))
                            .foregroundColor(Colors.primaryDark.opacity(0.6))
                        Text("\(tierUsed)")
                            .font(.LibreBodoniSemiBold(size: 16))
                            .foregroundColor(Colors.primaryDark)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("created")
                        .font(.LibreBodoniItalic(size: 11))
                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                    Text(match.formattedCreatedAt)
                        .font(Fonts.libreBodoni(size: 12))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                }
            }
            
            Divider()
                .background(Colors.primaryDark.opacity(0.2))
            
            // Members
            Text("members")
                .font(.LibreBodoniItalic(size: 14))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
            
            VStack(spacing: 8) {
                ForEach(match.members) { member in
                    Button(action: {
                        onMemberTap(member.userId)
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(member.displayName)
                                    .font(Fonts.libreBodoni(size: 16))
                                    .foregroundColor(Colors.primaryDark)
                                
                                if let city = member.city {
                                    Text(city)
                                        .font(Fonts.libreBodoni(size: 12))
                                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(Colors.primaryDark.opacity(0.4))
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Colors.background)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Colors.primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "active":
            return .green
        case "accepted":
            return .blue
        case "declined":
            return .red
        case "expired":
            return .orange
        default:
            return .gray
        }
    }
    
    private func scoreColor(for score: Double) -> Color {
        if score >= 0.7 {
            return .green
        } else if score >= 0.5 {
            return .orange
        } else {
            return .red.opacity(0.8)
        }
    }
}

// MARK: - User Card

private struct UserCard: View {
    let user: AdminUser
    @ObservedObject var adminModel: AdminModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and superadmin toggle
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName)
                        .font(.LibreBodoniSemiBold(size: 18))
                        .foregroundColor(Colors.primaryDark)
                    
                    Text(user.phone)
                        .font(Fonts.libreBodoni(size: 14))
                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                }
                
                Spacer()
                
                // Superadmin toggle
                Button(action: {
                    adminModel.toggleSuperadmin(for: user)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: user.superadmin ? "shield.fill" : "shield")
                            .font(.system(size: 14))
                        Text(user.superadmin ? "admin" : "user")
                            .font(Fonts.libreBodoni(size: 12))
                    }
                    .foregroundColor(user.superadmin ? .white : Colors.primaryDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(user.superadmin ? Colors.primaryDark : Colors.primaryDark.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Divider()
                .background(Colors.primaryDark.opacity(0.2))
            
            // User details
            VStack(alignment: .leading, spacing: 8) {
                if let age = user.age {
                    DetailRow(label: "age", value: "\(age)")
                }
                
                if let city = user.city {
                    DetailRow(label: "city", value: city)
                }
                
                if let almaMater = user.almaMater {
                    DetailRow(label: "alma mater", value: almaMater)
                }
                
                HStack(spacing: 16) {
                    StatusBadge(
                        text: user.onboarding ? "onboarding" : "onboarded",
                        color: user.onboarding ? .orange : .green
                    )
                    
                    StatusBadge(
                        text: user.verified ? "verified" : "unverified",
                        color: user.verified ? .blue : .gray
                    )
                }
                
                DetailRow(label: "joined", value: user.formattedCreatedAt)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Colors.primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Helper Views

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.LibreBodoniItalic(size: 14))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
            Spacer()
            Text(value)
                .font(Fonts.libreBodoni(size: 14))
                .foregroundColor(Colors.primaryDark)
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(Fonts.libreBodoni(size: 11))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .cornerRadius(6)
    }
}

// MARK: - User Details Sheet

private struct UserDetailsSheet: View {
    let userId: String
    @ObservedObject var adminModel: AdminModel
    @Environment(\.dismiss) var dismiss
    @State private var userDetails: AdminUserDetails?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showPastIntentions = false
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Fixed Header
                HStack {
                    Spacer()
                    Text("user details")
                        .font(.LibreBodoniSemiBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 20)
                .background(Colors.background)
                .overlay(alignment: .topTrailing) {
                    Button("done") {
                        dismiss()
                    }
                    .foregroundColor(Colors.primaryDark)
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                // Content
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("loading details...")
                            .font(Fonts.libreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else if let errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.7))
                        Text(errorMessage)
                            .font(Fonts.libreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                } else if let details = userDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // User Info Card
                            VStack(alignment: .leading, spacing: 12) {
                                Text(details.user.name)
                                    .font(.LibreBodoniSemiBold(size: 22))
                                    .foregroundColor(Colors.primaryDark)
                                
                                if let age = details.user.age {
                                    UserInfoRow(label: "age", value: "\(age)")
                                }
                                if let city = details.user.city {
                                    UserInfoRow(label: "city", value: city)
                                }
                                if let almaMater = details.user.almaMater {
                                    UserInfoRow(label: "alma mater", value: almaMater)
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            
                            // Survey Responses Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("survey responses")
                                    .font(.LibreBodoniSemiBold(size: 18))
                                    .foregroundColor(Colors.primaryDark)
                                
                                if details.survey.isEmpty {
                                    Text("no survey responses")
                                        .font(Fonts.libreBodoni(size: 14))
                                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                                } else {
                                    ForEach(details.survey, id: \.questionId) { response in
                                        SurveyResponseRow(response: response)
                                    }
                                }
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)
                            .cornerRadius(16)
                            
                            // Active Intention Card
                            if let activeIntention = details.activeIntention {
                                ActiveIntentionCard(intention: activeIntention)
                            }
                            
                            // Past Intentions Button
                            if !details.pastIntentions.isEmpty {
                                Button(action: {
                                    withAnimation {
                                        showPastIntentions.toggle()
                                    }
                                }) {
                                    HStack {
                                        Text(showPastIntentions ? "hide past intentions" : "show past intentions (\(details.pastIntentions.count))")
                                            .font(Fonts.libreBodoni(size: 14))
                                            .foregroundColor(Colors.primaryDark)
                                        Spacer()
                                        Image(systemName: showPastIntentions ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 12))
                                            .foregroundColor(Colors.primaryDark.opacity(0.6))
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                }
                                
                                if showPastIntentions {
                                    VStack(alignment: .leading, spacing: 12) {
                                        ForEach(details.pastIntentions) { intention in
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text(intention.text)
                                                    .font(Fonts.libreBodoni(size: 14))
                                                    .foregroundColor(Colors.primaryDark)
                                                
                                                HStack {
                                                    Text(intention.status)
                                                        .font(.LibreBodoniItalic(size: 11))
                                                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Colors.primaryDark.opacity(0.1))
                                                        .cornerRadius(6)
                                                    
                                                    Spacer()
                                                    
                                                    Text(intention.formattedCreatedAt)
                                                        .font(Fonts.libreBodoni(size: 11))
                                                        .foregroundColor(Colors.primaryDark.opacity(0.5))
                                                }
                                                
                                                if intention.id != details.pastIntentions.last?.id {
                                                    Divider()
                                                        .background(Colors.primaryDark.opacity(0.1))
                                                }
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .background(Color.white)
                                    .cornerRadius(16)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 40)
                    }
                    .background(Colors.background)
                }
            }
        }
        .onAppear {
            loadUserDetails()
        }
    }
    
    private func loadUserDetails() {
        isLoading = true
        errorMessage = nil
        
        adminModel.fetchUserDetails(userId: userId) { result in
            isLoading = false
            
            switch result {
            case .success(let details):
                userDetails = details
            case .failure(let error):
                errorMessage = "Failed to load details: \(error.localizedDescription)"
                print("❌ [AdminPanel] Failed to load user details: \(error)")
            }
        }
    }
}

// MARK: - Active Intention Card

private struct ActiveIntentionCard: View {
    let intention: AdminIntention
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("active intention")
                .font(.LibreBodoniSemiBold(size: 18))
                .foregroundColor(Colors.primaryDark)
            
            if let parsed = parseIntentionJson(intention.parsedJson, textFallback: intention.text) {
                // Looking For
                VStack(alignment: .leading, spacing: 8) {
                    Text("looking for")
                        .font(.LibreBodoniItalic(size: 13))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                    Text(parsed.intention)
                        .font(Fonts.libreBodoni(size: 16))
                        .foregroundColor(Colors.primaryDark)
                }
                
                Divider()
                    .background(Colors.primaryDark.opacity(0.2))
                
                // Activities
                VStack(alignment: .leading, spacing: 8) {
                    Text("activities")
                        .font(.LibreBodoniItalic(size: 13))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(parsed.activities, id: \.self) { activity in
                            Text(activity)
                                .font(Fonts.libreBodoni(size: 13))
                                .foregroundColor(Colors.primaryDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Colors.primaryDark.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                }
                
                Divider()
                    .background(Colors.primaryDark.opacity(0.2))
                
                // Availability
                VStack(alignment: .leading, spacing: 8) {
                    Text("availability")
                        .font(.LibreBodoniItalic(size: 13))
                        .foregroundColor(Colors.primaryDark.opacity(0.7))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(parsed.timeWindows, id: \.self) { timeWindow in
                            Text(timeWindow)
                                .font(Fonts.libreBodoni(size: 13))
                                .foregroundColor(Colors.primaryDark)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Colors.primaryDark.opacity(0.1))
                                .cornerRadius(20)
                        }
                    }
                    
                    if !parsed.location.isEmpty {
                        Text("near \(parsed.location)")
                            .font(Fonts.libreBodoni(size: 12))
                            .foregroundColor(Colors.primaryDark.opacity(0.6))
                            .padding(.top, 4)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("unable to parse intention data")
                        .font(.LibreBodoniItalic(size: 14))
                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                    
                    if !intention.text.isEmpty {
                        Text("Raw text: \(intention.text)")
                            .font(Fonts.libreBodoni(size: 12))
                            .foregroundColor(Colors.primaryDark.opacity(0.5))
                            .padding(.top, 4)
                    } else {
                        Text("No intention data available")
                            .font(Fonts.libreBodoni(size: 12))
                            .foregroundColor(Colors.primaryDark.opacity(0.5))
                            .padding(.top, 4)
                    }
                }
            }
            
            Divider()
                .background(Colors.primaryDark.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("status")
                        .font(.LibreBodoniItalic(size: 11))
                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                    Text(intention.status)
                        .font(Fonts.libreBodoni(size: 13))
                        .foregroundColor(Colors.primaryDark)
                }
                
                Spacer()
                
                if let poolEntry = intention.poolEntry {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("tier")
                            .font(.LibreBodoniItalic(size: 11))
                            .foregroundColor(Colors.primaryDark.opacity(0.6))
                        Text("\(poolEntry.tier)")
                            .font(Fonts.libreBodoni(size: 13))
                            .foregroundColor(Colors.primaryDark)
                    }
                }
            }
            
            Text("created \(intention.formattedCreatedAt)")
                .font(Fonts.libreBodoni(size: 11))
                .foregroundColor(Colors.primaryDark.opacity(0.5))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
    }
    
    private func parseIntentionJson(_ parsedJson: AnyCodable?, textFallback: String) -> (intention: String, activities: [String], timeWindows: [String], location: String)? {
        guard let json = parsedJson?.value as? [String: Any] else { return nil }
        
        var intentionType: String?
        var activities: [String] = []
        var availability: [String] = []
        var location: String = ""
        
        // Current format: { who: {}, what: { intention, activities }, when: [], where: "" }
        if let what = json["what"] as? [String: Any],
           let intent = what["intention"] as? String,
           let acts = what["activities"] as? [String] {
            intentionType = intent
            activities = acts
            availability = json["when"] as? [String] ?? []
            location = json["where"] as? String ?? ""
        }
        // Legacy format: { who: {}, what: { notes, activities }, when: [], location: "" }
        else if let what = json["what"] as? [String: Any],
                let notes = what["notes"] as? String,
                let acts = what["activities"] as? [String] {
            intentionType = notes.lowercased().contains("dating") || notes.lowercased().contains("romantic") ? "romantic" : "friends"
            activities = acts
            availability = json["when"] as? [String] ?? []
            location = json["location"] as? String ?? ""
        }
        
        guard let finalIntention = intentionType else { return nil }
        return (finalIntention, activities, availability, location)
    }
}

// MARK: - Survey Response Row

private struct SurveyResponseRow: View {
    let response: AdminSurveyResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(formatQuestionId(response.questionId))
                .font(.LibreBodoniItalic(size: 13))
                .foregroundColor(Colors.primaryDark.opacity(0.7))
            
            Text(formatValue(response.value.value))
                .font(Fonts.libreBodoni(size: 15))
                .foregroundColor(Colors.primaryDark)
        }
        .padding(.vertical, 4)
    }
    
    private func formatQuestionId(_ id: String) -> String {
        // Convert snake_case to title case
        id.split(separator: "_")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
    
    private func formatValue(_ value: Any) -> String {
        if let array = value as? [Any] {
            return array.map { "\($0)" }.joined(separator: ", ")
        }
        return "\(value)"
    }
}

// MARK: - User Info Row

private struct UserInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.LibreBodoniItalic(size: 13))
                .foregroundColor(Colors.primaryDark.opacity(0.6))
                .frame(width: 90, alignment: .leading)
            Text(value)
                .font(Fonts.libreBodoni(size: 15))
                .foregroundColor(Colors.primaryDark)
        }
    }
}

// MARK: - Unmatched Users Sheet

private struct UnmatchedUsersPage: View {
    @ObservedObject var adminModel: AdminModel
    @Environment(\.dismiss) var dismiss
    @State private var unmatchedUsers: [UnmatchedUserInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var hasMoreUsers = true
    @State private var currentPage = 0
    @State private var selectedUserId: String?
    @State private var showingUserDetails = false
    private let pageSize = 20
    
    var body: some View {
        ZStack {
            Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20))
                            .foregroundColor(Colors.primaryDark)
                    }
                    
                    Spacer()
                    
                    Text("unmatched users in pool")
                        .font(.LibreBodoniSemiBold(size: 20))
                        .foregroundColor(Colors.primaryDark)
                    
                    Spacer()
                    
                    Button(action: {
                        loadUnmatchedUsers(refresh: true)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 20))
                            .foregroundColor(Colors.primaryDark)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 20)
                .background(Colors.background)
                
                // Content
                if isLoading && unmatchedUsers.isEmpty {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("loading unmatched users...")
                            .font(Fonts.libreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                    }
                    .frame(maxHeight: .infinity)
                } else if let errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.red.opacity(0.7))
                        Text(errorMessage)
                            .font(Fonts.libreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxHeight: .infinity)
                } else if unmatchedUsers.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundColor(.green.opacity(0.7))
                        Text("no unmatched users in pool")
                            .font(Fonts.libreBodoni(size: 16))
                            .foregroundColor(Colors.primaryDark.opacity(0.7))
                        Text("all users with intentions have been matched!")
                            .font(Fonts.libreBodoni(size: 14))
                            .foregroundColor(Colors.primaryDark.opacity(0.5))
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Text("\(unmatchedUsers.count) user\(unmatchedUsers.count == 1 ? "" : "s") waiting for matches")
                                .font(.LibreBodoniItalic(size: 14))
                                .foregroundColor(Colors.primaryDark.opacity(0.7))
                                .padding(.horizontal, 16)
                                .padding(.top, 8)
                            
                            ForEach(unmatchedUsers, id: \.user.id) { details in
                                UnmatchedUserCard(
                                    userDetails: details,
                                    onTap: {
                                        selectedUserId = details.user.id
                                        showingUserDetails = true
                                    }
                                )
                                .onAppear {
                                    // Load more when reaching the last item
                                    let currentIndex = unmatchedUsers.firstIndex(where: { $0.user.id == details.user.id }) ?? 0
                                    let lastIndex = unmatchedUsers.count - 1
                                    
                                    if currentIndex == lastIndex && hasMoreUsers && !isLoading {
                                        loadUnmatchedUsers(refresh: false)
                                    }
                                }
                            }
                            
                            // Loading indicator at the bottom
                            if isLoading && !unmatchedUsers.isEmpty {
                                ProgressView()
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                    .background(Colors.background)
                }
            }
        }
        .sheet(isPresented: $showingUserDetails) {
            if let userId = selectedUserId {
                UserDetailsSheet(userId: userId, adminModel: adminModel)
            }
        }
        .onAppear {
            loadUnmatchedUsers(refresh: true)
        }
    }
    
    private func loadUnmatchedUsers(refresh: Bool = true) {
        // If refreshing, reset pagination
        if refresh {
            currentPage = 0
            unmatchedUsers = []
            hasMoreUsers = true
        }
        
        // Don't fetch if already loading or no more data
        guard !isLoading && hasMoreUsers else { 
            print("⚠️ Skipping fetch - isLoading: \(isLoading), hasMoreUsers: \(hasMoreUsers)")
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        let parameters: [String: Any] = [
            "page": currentPage,
            "limit": pageSize
        ]
        
        print("🔄 Fetching unmatched users - page: \(currentPage), limit: \(pageSize)")
        
        NetworkManager.shared.get(
            endpoint: "/admin/unmatched-users",
            parameters: parameters
        ) { [self] (result: Result<UnmatchedUsersResponse, NetworkError>) in
            DispatchQueue.main.async { [self] in
                self.isLoading = false
                
                switch result {
                case .success(let response):
                    print("✅ Received \(response.users.count) unmatched users from backend")
                    
                    if refresh {
                        self.unmatchedUsers = response.users
                    } else {
                        self.unmatchedUsers.append(contentsOf: response.users)
                    }
                    
                    // Check if there are more users to load
                    self.hasMoreUsers = response.users.count == self.pageSize
                    self.currentPage += 1
                    
                    print("✅ Total unmatched users: \(self.unmatchedUsers.count), hasMore: \(self.hasMoreUsers)")
                case .failure(let error):
                    print("❌ Failed to fetch unmatched users: \(error)")
                    self.errorMessage = "Failed to load unmatched users: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Unmatched User Card

private struct UnmatchedUserCard: View {
    let userDetails: UnmatchedUserInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // User Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(userDetails.user.name)
                            .font(.LibreBodoniSemiBold(size: 18))
                            .foregroundColor(Colors.primaryDark)
                        
                        if let city = userDetails.user.city {
                            Text(city)
                                .font(Fonts.libreBodoni(size: 14))
                                .foregroundColor(Colors.primaryDark.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    if let tier = userDetails.activeIntention?.poolEntry?.tier {
                        VStack(spacing: 4) {
                            Text("tier")
                                .font(.LibreBodoniItalic(size: 11))
                                .foregroundColor(Colors.primaryDark.opacity(0.6))
                            Text("\(tier)")
                                .font(.LibreBodoniSemiBold(size: 16))
                                .foregroundColor(tierColor(tier))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(tierColor(tier).opacity(0.15))
                        .cornerRadius(8)
                    }
                }
                
                // Intention Summary (if available)
                if let intention = userDetails.activeIntention,
                   let parsed = parseIntentionQuick(intention) {
                    Divider()
                        .background(Colors.primaryDark.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("looking for:")
                                .font(.LibreBodoniItalic(size: 12))
                                .foregroundColor(Colors.primaryDark.opacity(0.6))
                            Text(parsed.intention)
                                .font(Fonts.libreBodoni(size: 12))
                                .foregroundColor(Colors.primaryDark)
                        }
                        
                        if !parsed.activities.isEmpty {
                            FlowLayout(spacing: 6) {
                                ForEach(parsed.activities.prefix(3), id: \.self) { activity in
                                    Text(activity)
                                        .font(Fonts.libreBodoni(size: 11))
                                        .foregroundColor(Colors.primaryDark)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Colors.primaryDark.opacity(0.08))
                                        .cornerRadius(12)
                                }
                                if parsed.activities.count > 3 {
                                    Text("+\(parsed.activities.count - 3)")
                                        .font(Fonts.libreBodoni(size: 11))
                                        .foregroundColor(Colors.primaryDark.opacity(0.6))
                                }
                            }
                        }
                    }
                }
                
                // Tap hint
                HStack {
                    Spacer()
                    Text("tap for details")
                        .font(.LibreBodoniItalic(size: 11))
                        .foregroundColor(Colors.primaryDark.opacity(0.4))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(Colors.primaryDark.opacity(0.4))
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Colors.primaryDark.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    private func tierColor(_ tier: Int) -> Color {
        switch tier {
        case 0:
            return .green
        case 1:
            return .orange
        default:
            return .red
        }
    }
    
    private func parseIntentionQuick(_ intention: AdminIntention) -> (intention: String, activities: [String])? {
        // Quick parse for card display
        if let json = intention.parsedJson?.value as? [String: Any] {
            var intentionType: String?
            var activities: [String] = []
            
            if let what = json["what"] as? [String: Any],
               let intent = what["intention"] as? String,
               let acts = what["activities"] as? [String] {
                intentionType = intent
                activities = acts
            } else if let intent = json["intention"] as? String,
                      let acts = json["activities"] as? [String] {
                intentionType = intent
                activities = acts
            } else if let what = json["what"] as? [String: Any],
                      let notes = what["notes"] as? String,
                      let acts = what["activities"] as? [String] {
                intentionType = notes.lowercased().contains("romantic") ? "romantic" : "friends"
                activities = acts
            }
            
            if let finalIntention = intentionType {
                return (finalIntention, activities)
            }
        }
        
        // Fallback to text parsing
        if !intention.text.isEmpty,
           let parenStart = intention.text.firstIndex(of: "("),
           let parenEnd = intention.text.lastIndex(of: ")") {
            let parenContent = String(intention.text[intention.text.index(after: parenStart)..<parenEnd])
            let parts = parenContent.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            
            if parts.count >= 2 {
                let intentionStr = String(parts[0])
                let activities = parts[1..<min(parts.count - 1, 4)].map { String($0) }
                return (intentionStr, activities)
            }
        }
        
        return nil
    }
}

// MARK: - Preview

#Preview {
    AdminPanelView()
}


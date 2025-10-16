import SwiftUI
import PhotosUI
import AVFoundation

struct chat: View {
    var body: some View {
        Text("Hello World!")
    }
}

struct accounts: View {
    var body: some View {
        Text("Hello enter accounts!")
        
    }
}




enum MediaType {
    case text
    case image
    case link
    case document
    case poll
    case video
    
    var iconName: String {
        switch self {
        case .text: return "text.alignleft"
        case .image: return "photo"
        case .link: return "link"
        case .document: return "doc.text"
        case .poll: return "chart.bar"
        case .video: return "video"
        }
    }
}

// Define post sources
enum PostSource {
    case twitter
    case linkedin
    case instagram
    case facebook
    
    var name: String {
        switch self {
        case .twitter: return "Twitter"
        case .linkedin: return "LinkedIn"
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        }
    }
    
    var iconName: String {
        switch self {
        case .twitter: return "bubble.left.fill"
        case .linkedin: return "briefcase.fill"
        case .instagram: return "camera.fill"
        case .facebook: return "person.2.fill"
        }
    }
    
    var themeColor: Color {
        switch self {
        case .twitter: return Color.blue
        case .linkedin: return Color(red: 0.0, green: 0.47, blue: 0.71)
        case .instagram: return Color.purple
        case .facebook: return Color(red: 0.23, green: 0.35, blue: 0.6)
        }
    }
}

struct MediaPost: Identifiable {
    var id = UUID()
    var username: String
    var profileImage: String
    var mediaType: MediaType
    var mediaContent: String // URL, text, etc.
    var linkPreviewTitle: String?
    var linkPreviewDescription: String?
    var caption: String
    var likes: Int
    var comments: Int
    var shares: Int
    var timestamp: Date
    var source: PostSource
    var isEditing: Bool = false
    
    // Poll specific
    var pollOptions: [String]?
    var pollResults: [Int]?
    
    // Document specific
    var documentName: String?
    var documentSize: String?
}

struct MediaPostViewer: View {
    @State private var posts: [Post] = []
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach($posts) { $post in
                        EditablePostCardView(post: $post)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Your Posts")
        }
        .task {
            await loadPosts()
        }
        
        .background(Color.clear)
    }
    
    private func loadPosts() async {
        do {
            var postss = try await fetchPosts()
            print("posts \(postss)")
            DispatchQueue.main.async {
                for newPost in postss {
                    if !self.posts.contains(where: { $0.id == newPost.id }) {
                        self.posts.append(newPost)
                    }
                }
            }
        } catch {
            print("Error fetching posts: \(error)")
        }
    }
    
    private func fetchPosts() async throws -> [Post] {
        guard let userId = CoreDataManager.shared.fetchUserId() else {
            print("Error: User ID not found")
            return []
        }
        
        let baseURL = "http://localhost:5500"
        let urlString = "\(baseURL)/posts/\(userId)"
        
        return try await NetworkService.shared.fetchData(
            from: urlString,
            method: "GET",
            responseType: [Post].self
        )
    }
}


extension String {
    /// Returns the first URL found in the string, if any.
    func extractFirstURL() -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(location: 0, length: self.utf16.count)
        if let match = detector.firstMatch(in: self, options: [], range: range),
           let url = match.url {
            return url.absoluteString
        }
        return nil
    }
}





struct EditablePostCardView: View {
    @Binding var post: Post
    /// Callback to trigger deletion of the post.
    var onDelete: (() -> Void)?
    
    @State private var isEditing: Bool = false
    @State private var editedCaption: String = ""
    
    
    func shortTimestamp(from isoString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        // Include fractional seconds if your string has them
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Attempt to parse the ISO8601 string into a Date
        guard let date = isoFormatter.date(from: isoString) else {
            // If parsing fails, just return the original string
            return isoString
        }
        
        // Format the Date in a short, user-friendly style
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info and action buttons
            HStack {
                if let profileImage = post.profileImage, let url = URL(string: profileImage) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text(post.username ?? "Unknown User")
                        .font(.headline)
                    
                    HStack {
                        Text(post.source?.capitalized ?? "Unknown Source")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(shortTimestamp(from: post.timestamp!))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Edit and Delete buttons
                if isEditing {
                    Button("Cancel") {
                        isEditing = false
                        editedCaption = post.caption ?? ""
                    }
                    .foregroundColor(.red)
                } else {
    
                }
            }
            
            // Post content: either a TextEditor for editing or just a Text display
            if isEditing {
                TextEditor(text: $editedCaption)
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                if let caption = post.caption, !caption.isEmpty {
                    Text(caption)
                        .padding(.vertical, 4)
                }
            }
            
            // Media content, if available
            if let mediaType = post.mediaType, let mediaContent = post.mediaContent {
                renderMediaContent(type: mediaType, content: mediaContent)
            }
            
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    // Helper view for rendering media content dynamically
    @ViewBuilder
    private func renderMediaContent(type: String, content: String) -> some View {
        switch type.lowercased() {
        case "image":
            AsyncImage(url: URL(string: content)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 250)
            .cornerRadius(15)
            .clipped()
        case "video":
            ZStack {
                Color.black.frame(height: 250)
                Image(systemName: "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .cornerRadius(15)
        case "link":
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        default:
            EmptyView()
        }
    }
    
    // Format a Date? to a "time ago" string
    private func timeAgo(from timestamp: Date?) -> String {
        guard let date = timestamp else { return "Unknown time" }
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)
        if let day = components.day, day > 0 {
            return "\(day)d ago"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)h ago"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m ago"
        } else {
            return "Just now"
        }
    }
}

struct PostCardView: View {
    //    let post: Post
    @Binding var post: Post
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with user info
            HStack {
                if let profileImage = post.profileImage {
                    AsyncImage(url: URL(string: profileImage)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                }
                
                VStack(alignment: .leading) {
                    Text(post.username ?? "Unknown User")
                        .font(.headline)
                    
                    HStack {
                        Text(post.source?.capitalized ?? "Unknown Source")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .foregroundColor(.gray)
                        
                        Text(timeAgo(from: post.timestamp))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
            }
            
            // Post caption (if available)
            if let caption = post.caption, !caption.isEmpty {
                Text(caption)
                    .padding(.vertical, 4)
            }
            
            // Media content
            if let mediaType = post.mediaType, let mediaContent = post.mediaContent {
                renderMediaContent(type: mediaType, content: mediaContent)
            }
            
            // Post statistics
            HStack {
                if let likes = post.likes {
                    Text("\(likes) likes")
                        .font(.caption)
                }
                
                if let comments = post.comments {
                    Text("• \(comments) comments")
                        .font(.caption)
                }
                
                if let shares = post.shares {
                    Text("• \(shares) shares")
                        .font(.caption)
                }
                
                Spacer()
            }
            .foregroundColor(.gray)
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
    
    // Render media content
    @ViewBuilder
    private func renderMediaContent(type: String, content: String) -> some View {
        switch type.lowercased() {
        case "image":
            AsyncImage(url: URL(string: content)) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(height: 250)
            .cornerRadius(15)
            .clipped()
            
        case "video":
            ZStack {
                Color.black.frame(height: 250)
                Image(systemName: "play.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.black.opacity(0.6)))
            }
            .cornerRadius(15)
            
        case "link":
            VStack(alignment: .leading, spacing: 8) {
                Text(content)
                    .font(.caption)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            
        default:
            EmptyView()
        }
    }
    
    // Format timestamp string
    private func timeAgo(from timestamp: String?) -> String {
        guard let timestamp = timestamp, !timestamp.isEmpty else { return "Unknown time" }
        return timestamp // Adjust if a proper date format is needed
    }
}







//


struct Post:Identifiable ,Decodable {
    let id: Int?
    let userId: String
    let username: String?
    let profileImage: String?
    let mediaType: String?
    let mediaContent: String?
    var caption: String?
    let likes: Int?
    let comments: Int?
    let shares: Int?
    let timestamp: String?
    let source: String?
    // Optional additional fields if available
    let tweetId: String?
    let tweetUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case username
        case profileImage = "profile_image"
        case mediaType = "media_type"
        case mediaContent = "media_content"
        case caption
        case likes
        case comments
        case shares
        case timestamp
        case source
        case tweetId = "tweet_id"
        case tweetUrl = "tweet_url"
    }
}










//_________________________________________________________________________
import SwiftUI

struct UserProfileView: View {
    let email: String
    let userId: String
    var onLogout: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Profile Header
            Text("Profile")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 32)
            
            // User Info Card
            VStack(alignment: .leading, spacing: 16) {
                // Email
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                    Text("Email:")
                        .fontWeight(.medium)
                    Text(email)
                }
                
                // User ID
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                    Text("ID:")
                        .fontWeight(.medium)
                    Text(userId)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            
            Spacer()
            
            // Logout Button
            Button(action: onLogout) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Logout")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 32)
        }
        
        .background(Color.clear)
    }
}

// Preview provider for development
struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(
            email: "user@example.com",
            userId: "12345",
            onLogout: {}
        )
    }
}













































//_______________________________________________________________________________________

struct RegisterResponse: Decodable {
    let message: String
    let user: UserResponse.User
}
struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: UserResponse.User
}
struct UserResponse: Decodable {
    struct User: Decodable {
        let id: String
        let email: String
        let role: String
        let createdAt: String
        let updatedAt: String
        let userMetadata: UserMetadata
        let appMetadata: AppMetadata
    }
    
    struct UserMetadata: Decodable {
        let email: String
        let emailVerified: Bool
    }
    
    struct AppMetadata: Decodable {
        let provider: String
    }
}




//_______________________________________________________________
































import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    private let container: NSPersistentContainer
    
    
    
    private init() {
        container = NSPersistentContainer(name: "AuthDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
    }
    
    var context: NSManagedObjectContext {
        return container.viewContext
    }
    
    func saveContext() {
        if context.hasChanges {
            try? context.save()
        }
    }
    
    
    
    
    
    func saveSocialMediaData(_ accounts: [Account]) throws {
        var duplicates = [String]()
        let existingAccounts = try fetchExistingAccounts(accounts)
        
        // Batch create new entities
        for account in accounts {
            let exists = existingAccounts.contains {
                $0.name == account.name && $0.socialmedia == account.socialmedia
            }
            
            if exists {
                duplicates.append("\(account.name) (\(account.socialmedia))")
                continue
            }
            
            let newEntity = SocialMedia(context: context)
            newEntity.id = account.id
            newEntity.name = account.name
            newEntity.socialmedia = account.socialmedia
            newEntity.isSelected = account.isSelected
            
        }
        
        if !duplicates.isEmpty {
            throw NSError(
                domain: "CoreData",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Duplicate accounts found",
                    NSLocalizedRecoverySuggestionErrorKey: duplicates.joined(separator: ", ")
                ]
            )
        }
        
        try context.save()
    }
    
    private func fetchExistingAccounts(_ accounts: [Account]) throws -> [SocialMedia] {
        let predicates = accounts.map {
            NSPredicate(
                format: "name == %@ AND socialmedia == %@",
                $0.name,
                $0.socialmedia
            )
        }
        
        let compoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        let request: NSFetchRequest<SocialMedia> = SocialMedia.fetchRequest()
        request.predicate = compoundPredicate
        
        return try context.fetch(request)
    }
    
    
    func fetchAllSocialMedia() -> [SocialMedia] {
        let request: NSFetchRequest<SocialMedia> = SocialMedia.fetchRequest()
        return (try? context.fetch(request)) ?? []
    }
    
    func updateSocialMediaSelection(account: Account) {
        let request: NSFetchRequest<SocialMedia> = SocialMedia.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@ AND socialmedia == %@", account.id, account.socialmedia)
        
        if let entity = (try? context.fetch(request))?.first {
            entity.isSelected = account.isSelected
            saveContext()
        }
    }
    
    //    func deleteSocialMedia(account: Account) {
    //        let request: NSFetchRequest<SocialMedia> = SocialMedia.fetchRequest()
    //        request.predicate = NSPredicate(format: "id == %@", account.id)
    //
    //        if let entity = (try? context.fetch(request))?.first {
    //            context.delete(entity)
    //            saveContext()
    //        }
    //    }
    
    func deleteSocialMedia(account: Account) {
        let request: NSFetchRequest<SocialMedia> = SocialMedia.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", account.id)
        
        do {
            let results = try context.fetch(request)
            guard let entity = results.first else {
                print("Error: No matching account found in Core Data")
                return
            }
            
            context.delete(entity)
            saveContext()
        } catch {
            print("Error deleting account: \(error.localizedDescription)")
        }
    }
    
    
    
    
    // Save user to Core Data on USERENTITY
    func saveUser(_ user: UserResponse.User) {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", user.id)
        
        let existingUser = (try? context.fetch(request))?.first
        
        let userEntity = existingUser ?? UserEntity(context: context)
        userEntity.id = user.id
        userEntity.email = user.email
        userEntity.emailVerified = user.userMetadata.emailVerified
        userEntity.createdAt = ISO8601DateFormatter().date(from: user.createdAt) ?? Date()
        userEntity.updatedAt = ISO8601DateFormatter().date(from: user.updatedAt) ?? Date()
        userEntity.role = user.role
        userEntity.provider = user.appMetadata.provider
        
        saveContext()
    }
    
    // Fetch the logged-in user
    func fetchUser() -> UserEntity? {
        let request: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        return (try? context.fetch(request))?.first
    }
    
    func fetchUserId() -> String? {
        return fetchUser()?.id
    }
    
    func clearAllData() {
        let entityNames = container.managedObjectModel.entities.compactMap { $0.name }
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try container.persistentStoreCoordinator.execute(batchDeleteRequest, with: context)
            } catch {
                print("Failed to clear entity \(entityName): \(error.localizedDescription)")
            }
        }
        
        saveContext()
    }
    
}










































//_________________________________________________________________________________

import SwiftUI
struct AuthView: View {
    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    
    // For demonstration; you can remove or replace with your own logic.
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            // Title
            Text(isLogin ? "Hello." : "Create Account")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(isLogin ? "Welcome back" : "Join us today!")
                .font(.title3)
                .foregroundColor(.gray)
            
            // MARK: Email Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    
                    TextField("Enter email", text: $email)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(isLoading)
                }
                .padding()
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
            .padding(.horizontal)
            .padding(.top, 20)
            
            // MARK: Password Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                ZStack(alignment: .trailing) {
                    HStack {
                        Image(systemName: "lock")
                            .foregroundColor(.gray)
                        
                        if isPasswordVisible {
                            TextField("Enter password", text: $password)
                                .autocapitalization(.none)
                                .disabled(isLoading)
                        } else {
                            SecureField("Enter password", text: $password)
                                .disabled(isLoading)
                        }
                    }
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    
                    // Eye icon to toggle visibility
                    Button(action: {
                        isPasswordVisible.toggle()
                    }) {
                        Image(systemName: isPasswordVisible ? "eye.fill" : "eye.slash.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 8)
                    }
                    .disabled(isLoading)
                }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            
            // Forgot Password (only for login mode)
            if isLogin {
                HStack {
                    Spacer()
                    Button(action: {
                        // TODO: Forgot password logic
                    }) {
                        Text("Forgot password?")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    .disabled(isLoading)
                }
                .padding(.horizontal)
            }
            
            // MARK: Main Action Button (Login or Register)
            Button(action: {
                if isLogin {
                    Task { await handleLogin() }
                } else {
                    Task { await handleRegistration() }
                }
            }) {
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isLogin ? "Sign In" : "Register")
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(8)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .padding(.top, 20)
//            
//            // MARK: OR CONTINUE WITH
//            HStack {
//                Rectangle()
//                    .frame(height: 1)
//                    .foregroundColor(.gray.opacity(0.3))
//                
//                Text("OR WITH")
//                    .font(.footnote)
//                    .foregroundColor(.gray)
//                
//                Rectangle()
//                    .frame(height: 1)
//                    .foregroundColor(.gray.opacity(0.3))
//            }
//            .padding(.horizontal)
//            .padding(.top, 20)
//            
//            // MARK: Google & Apple Buttons
//            HStack(spacing: 16) {
//                Button(action: handleGoogleSignIn) {
//                    HStack {
//                        Image(systemName: "globe") // Replace with your Google icon
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                        Text("Google")
//                            .foregroundColor(.black)
//                    }
//                    .padding()
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(8)
//                }
//                .disabled(isLoading)
//                
//                Button(action: {
//                    // TODO: Apple sign-in logic
//                }) {
//                    HStack {
//                        Image(systemName: "applelogo")
//                            .resizable()
//                            .frame(width: 20, height: 20)
//                        Text("Apple")
//                            .foregroundColor(.black)
//                    }
//                    .padding()
//                    .background(Color.gray.opacity(0.1))
//                    .cornerRadius(8)
//                }
//                .disabled(isLoading)
//            }
//            .padding(.top, 10)
            
            Spacer()
            
            // MARK: Footer: Toggle Login/Sign Up
            HStack {
                Text(isLogin ? "Don't have an account?" : "Already have an account?")
                    .foregroundColor(.gray)
                Button(action: {
                    // Toggle between login and registration
                    isLogin.toggle()
                    email = ""
                    password = ""
                    isPasswordVisible = false
                }) {
                    Text(isLogin ? "Sign up" : "Sign in")
                        .foregroundColor(.blue)
                }
                .disabled(isLoading)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: 400) // Limit max width for a cleaner look
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Handle Login
    private func handleLogin() async {
        // Set loading state to true
        DispatchQueue.main.async {
            isLoading = true
        }
        
        let urlString = "http://localhost:5500/auth/login"
        let body: [String: String] = ["email": email, "password": password]
        
        do {
            let response: LoginResponse = try await NetworkService.shared.fetchData(
                from: urlString,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: try JSONSerialization.data(withJSONObject: body, options: []),
                responseType: LoginResponse.self
            )
            
            print("Response from login: \(response)")
            saveToKeychain(key: "accessToken", value: response.accessToken)
            saveToKeychain(key: "refreshToken", value: response.refreshToken)
            CoreDataManager.shared.saveUser(response.user)
            
            // Dismiss the login screen
            DispatchQueue.main.async {
                isLoading = false
                isAuthenticated = true
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Login failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    // MARK: - Handle Registration
    private func handleRegistration() async {
        // Set loading state to true
        DispatchQueue.main.async {
            isLoading = true
        }
        
        let urlString = "http://localhost:5500/auth/signup"
        let body: [String: String] = ["email": email, "password": password]
        
        do {
            let response: RegisterResponse = try await NetworkService.shared.fetchData(
                from: urlString,
                method: "POST",
                headers: ["Content-Type": "application/json"],
                body: try JSONSerialization.data(withJSONObject: body, options: []),
                responseType: RegisterResponse.self
            )
            
            //            CoreDataManager.shared.saveUser(response.user)
            
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Registration successful. Please log in."
                showAlert = true
                isLogin = true
            }
        } catch {
            DispatchQueue.main.async {
                isLoading = false
                alertMessage = "Registration failed: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
    
    // MARK: - Save to Keychain
    private func saveToKeychain(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    // MARK: - Handle Google Sign-In
    private func handleGoogleSignIn() {
        // Implement Google Sign-In logic here
    }
}





















































//________________________________________________________________________________________

import SwiftUI
@preconcurrency import WebKit

struct AccountsView: View {
    @State private var accountData: [String: [Account]] = [
        "Instagram": [], "Twitter": [], "YouTube": [], "TikTok": [],
        "Facebook": [], "LinkedIn": [], "Bluesky": [], "Threads": [], "Pinterest": []
    ]
    
    @State private var isWebViewPresented: Bool = false
    @State private var authURL: URL? = nil
    @State private var platformForDummy: String? = nil
    
    private var platforms: [(name: String, url: URL)] {
        [
            ("Twitter", buildAuthURL(for: "twitter"))
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(platforms, id: \.name) { platform in
                        AccountSection(
                            platformName: platform.name,
                            accounts: Binding(
                                get: { accountData[platform.name] ?? [] },
                                set: { accountData[platform.name] = $0 }
                            ),
                            connectAction: { openWebView(for: platform.name, url: platform.url) }
                        )
                    }
                }
                .padding()
            }
            .onAppear {
                Task { await loadSocialMediaData() }
            }
            .navigationTitle("Connected Accounts")
            .sheet(isPresented: $isWebViewPresented, onDismiss: handleBrowserDismissal) {
                //                if let authURL = authURL {
                //
                //                } else {
                //                    Text("Getting URL... Click again to authenticate.")
                //                }
                WebView( url: buildAuthURL(for: "twitter"), onClose: handleRedirect)
            }
        }
    }
    
    /// **Builds authentication URL dynamically**
    private func buildAuthURL(for platform: String) -> URL {
        //        print(">>> Building URL for %@\n", platform)
        var url = URL(string: "http://localhost:5500/auth/\(platform)")!
        
        if let userId = CoreDataManager.shared.fetchUserId() {
            var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
            urlComponents?.queryItems = [URLQueryItem(name: "userId", value: userId)]
            return urlComponents?.url ?? url
        }
        return url
    }
    
    /// **Open authentication in WebView**
    private func openWebView(for platform: String, url: URL) {
        authURL = url
        platformForDummy = platform
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isWebViewPresented = true
        }
    }
    
    /// **Handle authentication redirect**
    private func handleRedirect(_ url: URL) {
        if url.absoluteString.contains("twitter-success") {
            isWebViewPresented = false
            Task { await getUserAccounts() }
        }
    }
    
    
    /// **Handle WebView dismissal**
    private func handleBrowserDismissal() {
        print("Browser dismissed")
    }
    
    private func getUserAccounts() async {
        guard let userId = CoreDataManager.shared.fetchUserId() else {
            print("User ID not found")
            return
        }
        
        let urlString = "http://localhost:5500/getsocials/\(userId)"
        do {
            let response: [Account] = try await NetworkService.shared.fetchData(
                from: urlString,
                method: "GET",
                headers: ["Content-Type": "application/json"],
                responseType: [Account].self
            )
            print("Response from API: \(response)")
            
            try CoreDataManager.shared.saveSocialMediaData(response)
            DispatchQueue.main.async {
                Task {
                    await loadSocialMediaData()
                }
            }
        } catch {
            if let data = try? await NetworkService.shared.fetchRawData(from: urlString) {
                print("Raw JSON Response:", String(data: data, encoding: .utf8) ?? "Invalid data")
            }
        }
    }
    
    func loadSocialMediaData() async {
        let storedAccounts = CoreDataManager.shared.fetchAllSocialMedia()
        if storedAccounts.isEmpty {
            print("Error: No social media data found in Core Data. getting media from supabase...")
            await getUserAccounts()
            return
        }
        
        var groupedAccounts = accountData
        for entity in storedAccounts {
            let account = Account(
                id: entity.id ?? UUID().uuidString,
                name: entity.name ?? "",
                socialmedia: entity.socialmedia ?? "",
                isSelected: entity.isSelected
            )
            
            if groupedAccounts[account.socialmedia]?.contains(where: { $0.id == account.id }) == false {
                groupedAccounts[account.socialmedia, default: []].append(account)
            }
        }
        accountData = groupedAccounts
    }
    
    
}

/// **WebView with Cookie Clearing**
struct WebView: UIViewRepresentable {
    let url : URL
    var onClose: (URL) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        clearCookies {
            webView.load(URLRequest(url: url))
        }
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, onClose: onClose)
    }
    
    private func clearCookies(completion: @escaping () -> Void) {
        let dataStore = WKWebsiteDataStore.default()
        let dataTypes: Set<String> = [WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage]
        
        dataStore.fetchDataRecords(ofTypes: dataTypes) { records in
            dataStore.removeData(ofTypes: dataTypes, modifiedSince: Date.distantPast) {
                print("Cookies Cleared")
                DispatchQueue.main.async { completion() }
            }
        }
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: WebView
        var onClose: (URL) -> Void
        
        init(_ parent: WebView, onClose: @escaping (URL) -> Void) {
            self.parent = parent
            self.onClose = onClose
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url, url.absoluteString.contains("twitter-success") {
                DispatchQueue.main.async {
                    webView.stopLoading()
                    self.onClose(url)
                }
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}



/// A reusable view for each account section
struct AccountSection: View {
    let platformName: String
    @Binding var accounts: [Account]
    let connectAction: () -> Void
    @State private var isExpanded: Bool = false // State for collapsing/expanding the list
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with button to connect accounts and toggle collapsibility
            HStack {
                Button(action: connectAction) {
                    HStack {
                        //                        Image(systemName: "plus.circle.fill")
                        Image("x").resizable().scaledToFit().frame(width: 60, height: 60).clipShape(Circle())
                        //
                        Text("Connect \(platformName)")
                            .font(.headline)
                    }
                }
                .background(Color.white)
                Spacer()
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            
            // List of connected accounts, shown only if expanded
            if isExpanded {
                ForEach($accounts, id: \.id) { $account in
                    HStack {
                        Toggle(isOn: Binding(
                            get: { account.isSelected },
                            set: { newValue in
                                account.isSelected = newValue
                                CoreDataManager.shared.updateSocialMediaSelection(account: account)
                            }
                        )) {
                            Text(account.name)
                                .font(.body)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .blue))
                        Spacer()
                        Button(action: {
                            // Delete the account
                            //                            accounts.removeAll { $0.id == account.id }
                            //                            CoreDataManager.shared.deleteSocialMedia(account: account)
                            guard let index = accounts.firstIndex(where: { $0.id == account.id }) else {
                                print("Error: Account not found in list")
                                return
                            }
                            
                            
                            
                            guard let userId = CoreDataManager.shared.fetchUserId() else {
                                print("User ID not found")
                                return
                            }
                            
                            // ✅ Ensure safe UI update
                            
                            
                            deleteUserSocial(userId: userId, username: account.name, socialmedia: account.socialmedia) { result in
                                switch result {
                                case .success(let message):
                                    DispatchQueue.main.async {
                                        // ✅ Remove from Core Data
                                        CoreDataManager.shared.deleteSocialMedia(account: account)
                                        accounts.remove(at: index)
                                    }
                                    print("✅ Success: \(message)")
                                case .failure(let error):
                                    print("❌ Error: \(error.localizedDescription)")
                                }
                            }
                            
                            
                            
                        }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    
    /// Request model for deleting a social media account.
    struct DeleteSocialRequest: Encodable {
        let user_id: String
        let username: String
        let socialmedia: String
    }
    
    /// Response model for handling API responses.
    struct DeleteSocialResponse: Decodable {
        let success: Bool
        let message: String
    }
    
    /// Function to delete a social media account using `NetworkService`
    func deleteUserSocial(
        userId: String,
        username: String,
        socialmedia: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let url = "http://localhost:5500/deletesocials/"
        let requestBody = DeleteSocialRequest(user_id: userId, username: username, socialmedia: socialmedia)
        
        Task {
            do {
                let requestData = try JSONEncoder().encode(requestBody) // Convert model to JSON
                
                let response: DeleteSocialResponse = try await NetworkService.shared.fetchData(
                    from: url,
                    method: "DELETE", // Change to "DELETE" if API requires it
                    headers: ["Content-Type": "application/json"],
                    body: requestData,
                    responseType: DeleteSocialResponse.self
                )
                
                if response.success {
                    completion(.success("Successfully deleted \(socialmedia) for \(username)"))
                } else {
                    completion(.failure(NSError(domain: "DeleteError", code: 400, userInfo: [NSLocalizedDescriptionKey: response.message])))
                }
                
            } catch {
                completion(.failure(error))
            }
        }
    }
}











































/// A struct to represent an account
struct Account: Identifiable, Codable {
    let id: String
    var name: String
    var socialmedia: String
    var isSelected: Bool
}


struct AccountsView_Previews: PreviewProvider {
    static var previews: some View {
        AccountsView()
    }
}


















































































//----------------------------------------------------------------------------------------

import Foundation

/// A singleton service for handling network requests.
final class NetworkService {
    static let shared = NetworkService() // Singleton instance
    private init() {}
    
    /// Generic function for making API requests.
    func fetchData<T: Decodable>(
        from urlString: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        // 1. Validate URL
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        // 2. Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // 3. Execute Request
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        // 4. Decode Response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
    
    /// Generic function to handle raw data responses (e.g., files, images).
    func fetchRawData(
        from urlString: String,
        method: String = "GET",
        headers: [String: String]? = nil,
        body: Data? = nil
    ) async throws -> Data {
        // 1. Validate URL
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        // 2. Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        // 3. Execute Request
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        
        return data
    }
    
    /// Helper function to validate HTTP responses.
    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.requestFailed(statusCode: httpResponse.statusCode)
        }
    }
}

/// API Error Enum
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .invalidResponse:
            return "The response from the server was invalid."
        case .requestFailed(let statusCode):
            return "Request failed with status code \(statusCode)."
        case .decodingFailed(let error):
            return "Decoding failed: \(error.localizedDescription)"
        case .custom(let message):
            return message
        }
    }
}


//----------------------------------------------------------------------------------------------


struct SchedulingResult {
    let scheduled: Bool
    let scheduledTime: Date?
    let scheduledTimeMs: TimeInterval? // time in milliseconds since epoch
    let timeDescription: String?
    let scheduledTimeFormatted: String?
    let postContent: String
    let command: String?
}



class PostScheduler {
    
    /// Converts a time amount and unit into milliseconds.
    /// - Parameters:
    ///   - amount: The numeric value.
    ///   - unit: The time unit (e.g. "seconds", "minutes", "hours", "days").
    /// - Returns: The corresponding milliseconds.
    static func convertToMilliseconds(amount: Int, unit: String) -> TimeInterval {
        let lower = unit.lowercased()
        if lower.hasPrefix("second") || lower == "sec" || lower == "secs" {
            return TimeInterval(amount * 1000)
        } else if lower.hasPrefix("minute") || lower == "min" || lower == "mins" {
            return TimeInterval(amount * 60 * 1000)
        } else if lower.hasPrefix("hour") || lower == "hr" || lower == "hrs" {
            return TimeInterval(amount * 60 * 60 * 1000)
        } else if lower.hasPrefix("day") {
            return TimeInterval(amount * 24 * 60 * 60 * 1000)
        }
        return 0
    }
    
    /// Array of scheduling rules: each rule contains a regex pattern and a handler that processes matched groups.
    static let schedulingRules: [(pattern: String, handler: ([String]) -> (Date, String)?)] = [
        // Relative time: "post this in X seconds/minutes/hours/days"
        (
            pattern: "post this in (\\d+)\\s*(second|seconds|sec|secs|minute|minutes|min|mins|hour|hours|hr|hrs|day|days)",
            handler: { groups in
                // groups[0] is the full match, groups[1] is the amount, groups[2] is the unit.
                guard groups.count >= 3, let amount = Int(groups[1]) else { return nil }
                let unit = groups[2]
                let millis = PostScheduler.convertToMilliseconds(amount: amount, unit: unit)
                let scheduledTime = Date().addingTimeInterval(millis / 1000)
                return (scheduledTime, "in \(amount) \(unit)")
            }
        ),
        // Specific time: "post this at HH:MM AM/PM"
        (
            pattern: "post this at (\\d{1,2}):(\\d{2})\\s*(am|pm)?",
            handler: { groups in
                guard groups.count >= 3,
                      let hourRaw = Int(groups[1]),
                      let minutes = Int(groups[2]) else { return nil }
                var hours = hourRaw
                let period = groups.count > 3 ? groups[3].lowercased() : ""
                if period == "pm" && hours < 12 { hours += 12 }
                else if period == "am" && hours == 12 { hours = 0 }
                let calendar = Calendar.current
                var scheduledTime = calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: Date()) ?? Date()
                if scheduledTime < Date() {
                    scheduledTime = calendar.date(byAdding: .day, value: 1, to: scheduledTime) ?? scheduledTime
                }
                return (scheduledTime, "at \(groups[1]):\(groups[2]) \(period)")
            }
        ),
        // Specific date and time: "post this on MM/DD/YYYY at HH:MM AM/PM"
        (
            pattern: "post this on (\\d{1,2})/(\\d{1,2})(?:/(\\d{2,4}))?\\s*at\\s*(\\d{1,2}):(\\d{2})\\s*(am|pm)?",
            handler: { groups in
                guard groups.count >= 6,
                      let month = Int(groups[1]),
                      let day = Int(groups[2]) else { return nil }
                var year: Int = groups[3].isEmpty ? Calendar.current.component(.year, from: Date()) : Int(groups[3]) ?? Calendar.current.component(.year, from: Date())
                if year < 100 { year += 2000 }
                var hours = Int(groups[4]) ?? 0
                let minutes = Int(groups[5]) ?? 0
                let period = groups.count > 6 ? groups[6].lowercased() : ""
                if period == "pm" && hours < 12 { hours += 12 }
                else if period == "am" && hours == 12 { hours = 0 }
                
                var comps = DateComponents()
                comps.year = year
                comps.month = month
                comps.day = day
                comps.hour = hours
                comps.minute = minutes
                comps.second = 0
                let scheduledTime = Calendar.current.date(from: comps) ?? Date()
                return (scheduledTime, "on \(month)/\(day)/\(year) at \(groups[4]):\(groups[5]) \(period)")
            }
        ),
        // Natural language: "post this tomorrow at HH:MM AM/PM" or "post this next Monday"
        (
            pattern: "post this (tomorrow|next (monday|tuesday|wednesday|thursday|friday|saturday|sunday))(?:\\s*at\\s*(\\d{1,2}):(\\d{2})\\s*(am|pm)?)?",
            handler: { groups in
                let dateText = groups[1].lowercased()
                let calendar = Calendar.current
                var scheduledTime = Date()
                if dateText == "tomorrow" {
                    scheduledTime = calendar.date(byAdding: .day, value: 1, to: scheduledTime) ?? scheduledTime
                } else if dateText.hasPrefix("next "), groups.count >= 3 {
                    let targetDay = groups[2].lowercased()
                    let daysOfWeek = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
                    guard let targetIndex = daysOfWeek.firstIndex(of: targetDay) else { return nil }
                    let currentDay = calendar.component(.weekday, from: scheduledTime) - 1 // Sunday=0
                    var daysToAdd = targetIndex - currentDay
                    if daysToAdd <= 0 { daysToAdd += 7 }
                    scheduledTime = calendar.date(byAdding: .day, value: daysToAdd, to: scheduledTime) ?? scheduledTime
                }
                if groups.count >= 6, let hourRaw = Int(groups[3]), let minutes = Int(groups[4]) {
                    var hours = hourRaw
                    let period = groups[5].lowercased()
                    if period == "pm" && hours < 12 { hours += 12 }
                    else if period == "am" && hours == 12 { hours = 0 }
                    scheduledTime = calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: scheduledTime) ?? scheduledTime
                    return (scheduledTime, "\(dateText) at \(groups[3]):\(groups[4]) \(period)")
                } else {
                    // Default time if not provided
                    scheduledTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: scheduledTime) ?? scheduledTime
                    return (scheduledTime, "\(dateText) at 9:00 AM")
                }
            }
        )
    ]
    
    /// Analyzes the given user text for scheduling commands.
    /// - Parameters:
    ///   - userText: The complete text input from the user.
    ///   - scheduleCallback: A callback to execute when a scheduling command is found.
    /// - Returns: A SchedulingResult containing scheduling info and the post content.
    static func analyzeAndSchedulePost(userText: String, scheduleCallback: (String, Date) -> Void) -> SchedulingResult {
        for rule in schedulingRules {
            do {
                let regex = try NSRegularExpression(pattern: rule.pattern, options: .caseInsensitive)
                let nsString = userText as NSString
                let results = regex.matches(in: userText, options: [], range: NSRange(location: 0, length: nsString.length))
                if let match = results.first {
                    // Extract all matched groups.
                    var groups: [String] = []
                    for i in 0..<match.numberOfRanges {
                        let range = match.range(at: i)
                        let group = (range.location != NSNotFound) ? nsString.substring(with: range) : ""
                        groups.append(group)
                    }
                    if let (scheduledTime, timeDescription) = rule.handler(groups) {
                        // Remove the scheduling command from the input text.
                        let command = groups.first ?? ""
                        let postContent = userText.replacingOccurrences(of: command, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Execute the schedule callback.
                        scheduleCallback(postContent, scheduledTime)
                        
                        return SchedulingResult(
                            scheduled: true,
                            scheduledTime: scheduledTime,
                            scheduledTimeMs: scheduledTime.timeIntervalSince1970 * 1000,
                            timeDescription: timeDescription,
                            scheduledTimeFormatted: DateFormatter.localizedString(from: scheduledTime, dateStyle: .short, timeStyle: .short),
                            postContent: postContent,
                            command: command
                        )
                    }
                }
            } catch {
                print("Regex error: \(error)")
            }
        }
        // No scheduling command detected; return unscheduled result.
        return SchedulingResult(
            scheduled: false,
            scheduledTime: nil,
            scheduledTimeMs: nil,
            timeDescription: nil,
            scheduledTimeFormatted: nil,
            postContent: userText,
            command: nil
        )
    }
}


















//------------------------------------------------------------------------------------

import Foundation
import UIKit


import Foundation

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var userInput: String = ""
    @Published var selectedImages: [UIImage] = []
    @Published var recordedAudioURL: URL?
    
    @State private var messageIdCounter: Int = 1 // Ensure IDs are sequential and unique
    
    
    @Published  var recordedAudioDuration: TimeInterval = 0.0
    
    
    @Published  var selectedMessages: Set<UUID> = []
    
    @Published var errorMessage: String?
    @Published var isErrorMessage: Bool = false
    
    
    
    private let textAPIURL = "http://localhost:5500/ai/chat"
    private let textWithImageAPIURL = "http://localhost:5500/chat-with-image"
    private let transcriptionAPIURL = "http://localhost:5500/ai/audio"
    private let postAPIURL = "http://localhost:5500/ai/post"
    
    
    func schedulePost(content: String, scheduledTime: Date) {
        let now = Date()
        let delay = scheduledTime.timeIntervalSince(now)
        print("Post scheduled for \(scheduledTime) (\(delay) seconds from now)")
        // Here you would trigger your actual posting logic.
        
        var social = loadSocialMediaData()
        
        if social.isEmpty {
            self.errorMessage = "No social media selected or avaliable to post on"
            self.isErrorMessage = true
            
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.isErrorMessage = false
            }
            print(self.errorMessage)
            return
        }
        
        
        print("socials might be multiple \(social)")
        
        let userId = CoreDataManager.shared.fetchUserId()!
        
        prepareAndSendFormData(prompt: userInput, selectedUUIDs: Array(selectedMessages), messages: messages, socials: social, userid: userId, scheduledTime: scheduledTime)
    }
    
    
    
    
    func sendMessage() {
        guard !userInput.isEmpty || !selectedImages.isEmpty || recordedAudioURL != nil else { return }
        
        let classify = classifyContentType(prompt: userInput)
        
        if classify == "post" {
            print("post instruction")
            
            let schedulingResult = PostScheduler.analyzeAndSchedulePost(userText: userInput, scheduleCallback: schedulePost)
            print(schedulingResult)
            
            if schedulingResult.scheduled == false {
                
                
                print(extractMessagesContentAsData(by: Array(selectedMessages), from: messages))
                
                
                var social = loadSocialMediaData()
                
                if social.isEmpty {
                    self.errorMessage = "No social media selected or avaliable to post on"
                    self.isErrorMessage = true
                    
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.isErrorMessage = false
                    }
                    //                    print(self.errorMessage)
                    return
                }
                
                
                //                print("socials might be multiple \(social)")
                
                let userId = CoreDataManager.shared.fetchUserId()!
                
                prepareAndSendFormData(prompt: userInput, selectedUUIDs: Array(selectedMessages), messages: messages, socials: social, userid: userId, scheduledTime: nil)
                
                
            }
            
            
            if selectedMessages.isEmpty {
                print("no content to post")
                return
            }
            
            
            
            
        }else{
            print("regular prompt")
            // Handle text-only messages
            if !userInput.isEmpty && selectedImages.isEmpty && recordedAudioURL == nil {
                messages.append(Message(id: UUID(), type: .text(userInput), sender: .user))
                sendTextMessage(text: userInput)
                userInput = ""
            }
            
            
            
            
            if !userInput.isEmpty && !selectedImages.isEmpty {
                let textMessage = Message(
                    id: UUID(),
                    type: .text(userInput),
                    sender: .user
                )
                
                let imageMessage = Message(
                    id: UUID(),
                    type: .image(selectedImages), // Group images into one message
                    sender: .user
                )
                
                messages.append(textMessage)
                messages.append(imageMessage)
                
                sendTextAndImageMessage(text: userInput, images: selectedImages)
                userInput = ""
                selectedImages.removeAll()
            }
            
            // Handle images-only
            if userInput.isEmpty && !selectedImages.isEmpty {
                let imageMessage = Message(
                    id: UUID(),
                    type: .image(selectedImages), // Group images into one message
                    sender: .user
                )
                
                messages.append(imageMessage)
                /*sendImagesOnlyMessage(images: selectedImages)*/ // Optional method for handling images-only cases
                selectedImages.removeAll()
            }
            
            
            
            
            // Handle voice notes
            if let audioURL = recordedAudioURL {
                transcribeAudio(url: audioURL)
                recordedAudioURL = nil
                recordedAudioDuration = 0.00
                print("sending voice note")
            }
        }
        
        
    }
    
    private func sendTextMessage(text: String) {
        let userId = CoreDataManager.shared.fetchUserId()!
        let body: [String: String] = ["prompt": text, "user_id": userId]
        
        guard let encodedBody = try? JSONEncoder().encode(body) else { return }
        
        Task {
            do {
                let chatResponse: ChatResponse = try await NetworkService.shared.fetchData(
                    from: textAPIURL,
                    method: "POST",
                    headers: ["Content-Type": "application/json"],
                    body: encodedBody,
                    responseType: ChatResponse.self
                )
                DispatchQueue.main.async {
                    self.appendAssistantResponse(chatResponse)
                }
            } catch {
                print("Error sending text message: \(error.localizedDescription)")
            }
        }
    }
    
    func classifyContentType(prompt: String) -> String {
        let lowerPrompt = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Define post-related keywords
        let postKeywords = ["post this", "share this", "upload this", "publish this", "make a post"]
        
        // Check if the input is a post instruction
        for keyword in postKeywords {
            if lowerPrompt.contains(keyword) {
                return "post"  // Ensure strict separation of post requests
            }
        }
        
        // If no post instruction, classify as text
        return "prompt"
    }
    
    private func sendTextAndImageMessage(text: String, images: [UIImage]) {
        let userId = CoreDataManager.shared.fetchUserId()!
        let boundary = UUID().uuidString
        var body = Data()
        
        // Append the text field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"message\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(text)\r\n".data(using: .utf8)!)
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"user_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(userId)\r\n".data(using: .utf8)!)
        
        // Append the image files
        for (index, image) in images.enumerated() {
            if let imageData = image.jpegData(compressionQuality: 0.8) {
                body.append("--\(boundary)\r\n".data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"images\"; filename=\"image\(index).jpg\"\r\n".data(using: .utf8)!)
                body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
                body.append(imageData)
                body.append("\r\n".data(using: .utf8)!)
            }
        }
        
        // Close the boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        
        Task {
            do {
                let chatResponse: ChatResponsefromImageApi = try await NetworkService.shared.fetchData(
                    from: textWithImageAPIURL,
                    method: "POST",
                    headers: headers,
                    body: body,
                    responseType: ChatResponsefromImageApi.self
                )
                DispatchQueue.main.async {
                    self.appendAssistantResponse(chatResponse)
                }
            } catch {
                print("Error sending text and image message: \(error.localizedDescription)")
            }
        }
    }
    
    private func transcribeAudio(url: URL) {
        let boundary = UUID().uuidString
        var body = Data()
        
        if let audioData = try? Data(contentsOf: url) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
            body.append(audioData)
            body.append("\r\n".data(using: .utf8)!)
        }
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        let headers = ["Content-Type": "multipart/form-data; boundary=\(boundary)"]
        
        Task {
            do {
                let transcriptionResponse: TranscriptionResponse = try await NetworkService.shared.fetchData(
                    from: transcriptionAPIURL,
                    method: "POST",
                    headers: headers,
                    body: body,
                    responseType: TranscriptionResponse.self
                )
                DispatchQueue.main.async {
                    let aiMessage = Message(id: UUID(), type: .text(transcriptionResponse.transcription), sender: .user)
                    self.messages.append(aiMessage)
                    self.sendTextMessage(text: transcriptionResponse.transcription)
                }
            } catch {
                print("Error transcribing audio: \(error.localizedDescription)")
            }
        }
    }
    
    
    private func appendAssistantResponse(_ chatResponse: ChatResponse) {
        // Process text response on the main thread.
        DispatchQueue.main.async {
            if let aiText = chatResponse.text {
                let aiTextMessage = Message(id: UUID(), type: .text(aiText), sender: .assistant)
                self.messages.append(aiTextMessage)
            }
        }
        
        // Process images: each image URL is loaded and added as its own message.
        if let images = chatResponse.images {
            for imageUrl in images {
                if let url = URL(string: imageUrl) {
                    URLSession.shared.dataTask(with: url) { data, response, error in
                        if let error = error {
                            print("Error loading image from \(url): \(error.localizedDescription)")
                            return
                        }
                        
                        guard let data = data, let image = UIImage(data: data) else {
                            print("Failed to create image from data for URL: \(url)")
                            return
                        }
                        
                        // Update UI on the main thread for each image.
                        DispatchQueue.main.async {
                            let imageMessage = Message(id: UUID(), type: .image([image]), sender: .assistant)
                            self.messages.append(imageMessage)
                        }
                    }.resume()
                } else {
                    print("Invalid URL: \(imageUrl)")
                }
            }
        }
    }
    
    
    private func appendAssistantResponse(_ chatResponse: ChatResponsefromImageApi) {
        let aiTextMessage = Message(id: UUID(), type: .text(chatResponse.response), sender: .assistant)
        messages.append(aiTextMessage)
    }
    
    
    
    func extractMessagesContentAsData(by uuids: [UUID], from messages: [Message]) -> [(id: UUID, content: Any)] {
        return messages
            .filter { uuids.contains($0.id) }  // Filter messages by UUID
            .compactMap { message in
                switch message.type {
                case .text(let text):
                    return (id: message.id, content: text as Any)  // Return text
                case .image(let images):
                    let imageDataArray = images.compactMap { $0.jpegData(compressionQuality: 1.0) } // Convert UIImage to Data
                    return imageDataArray.isEmpty ? nil : (id: message.id, content: imageDataArray as Any)  // Return image data
                case .voice(_):
                    print(">>> Voice message")
                    return nil
                }
            }
    }
    
    
    func prepareAndSendFormData(prompt: String, selectedUUIDs: [UUID], messages: [Message], socials:[Account], userid:String, scheduledTime: Date?) {
        let boundary = "Boundary-\(UUID().uuidString)"
        var formData = Data()
        
        // 1️⃣ Add the `prompt` field
        let promptField = "--\(boundary)\r\n"
        + "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
        + "\(prompt)\r\n"
        formData.append(promptField.data(using: .utf8)!)
        
        
        //     send socials
        
        //        let socialField = "--\(boundary)\r\n"
        //            + "Content-Disposition: form-data; name=\"socials\"\r\n\r\n"
        //        + "\(socials)\r\n"
        //        formData.append(socialField.data(using: .utf8)!)
        
        do {
            let socialsJSONData = try JSONEncoder().encode(socials)
            if let socialsJSONString = String(data: socialsJSONData, encoding: .utf8) {
                let socialField = "--\(boundary)\r\n"
                + "Content-Disposition: form-data; name=\"socials\"\r\n\r\n"
                + "\(socialsJSONString)\r\n"
                formData.append(socialField.data(using: .utf8)!)
            }
        } catch {
            print("❌ Error encoding socials JSON: \(error)")
            return
        }
        
        let userIDField = "--\(boundary)\r\n"
        + "Content-Disposition: form-data; name=\"userid\"\r\n\r\n"
        + "\(userid)\r\n"
        formData.append(userIDField.data(using: .utf8)!)
        
        
        
        
        // 2️⃣ Extract selected text & images and append them as `data`
        let extractedContents = extractMessagesContentAsData(by: selectedUUIDs, from: messages)
        
        for (index, (id, content)) in extractedContents.enumerated() {
            if let text = content as? String {
                let fieldName = "data[text][\(index)]"
                let textPart = "--\(boundary)\r\n"
                + "Content-Disposition: form-data; name=\"data\"\r\n\r\n"
                + "\(text)\r\n"
                formData.append(textPart.data(using: .utf8)!)
            } else if let imagesData = content as? [Data] {
                for imageData in imagesData {
                    let filename = "image_\(UUID().uuidString).jpg" // Unique filename
                    let mimeType = "image/jpeg"
                    
                    let imagePart = "--\(boundary)\r\n"
                    + "Content-Disposition: form-data; name=\"images\"; filename=\"\(filename)\"\r\n"
                    + "Content-Type: \(mimeType)\r\n\r\n"
                    
                    formData.append(imagePart.data(using: .utf8)!)
                    formData.append(imageData) // Attach raw image data
                    formData.append("\r\n".data(using: .utf8)!)
                }
            }
            
        }
        
        // Append scheduled time only if provided.
        if let scheduledTime = scheduledTime {
            let timestamp = Int(scheduledTime.timeIntervalSince1970 * 1000) // milliseconds
            let timestampField = "--\(boundary)\r\n"
            + "Content-Disposition: form-data; name=\"timestamp\"\r\n\r\n"
            + "\(timestamp)\r\n"
            formData.append(timestampField.data(using: .utf8)!)
        }
        
        
        // 3️⃣ Close the boundary
        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // 4️⃣ Send to backend
        sendFormData(formData: formData, boundary: boundary)
    }
    
    func sendFormData(formData: Data, boundary: String) {
        
        
        let headers = [
            "Content-Type": "multipart/form-data; boundary=\(boundary)"
        ]
        
        Task {
            do {
                let chatResponse: ChatResponsefromImageApi = try await NetworkService.shared.fetchData(
                    from: postAPIURL,
                    method: "POST",
                    headers: headers,
                    body: formData,
                    responseType: ChatResponsefromImageApi.self
                )
                DispatchQueue.main.async {
                    self.appendAssistantResponse(chatResponse)
                    self.selectedMessages = []
                }
            } catch {
                print("❌ Error sending text and image message: \(error.localizedDescription)")
            }
        }
    }
    
    
    func loadSocialMediaData() -> [Account] {
        let storedAccounts = CoreDataManager.shared.fetchAllSocialMedia()
        
        // If no accounts are stored, log an error and return an empty array.
        guard !storedAccounts.isEmpty else {
            print("Error: No social media data found in Core Data.")
            return []
        }
        
        // Create an array to hold the Account objects.
        var accounts: [Account] = []
        
        // Loop through each Core Data entity and convert it to an Account.
        for entity in storedAccounts {
            let account = Account(
                id: entity.id ?? UUID().uuidString,
                name: entity.name ?? "",
                socialmedia: entity.socialmedia ?? "",
                isSelected: entity.isSelected
            )
            accounts.append(account)
        }
        
        // Return the list of accounts.
        return accounts.filter { $0.isSelected }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    

    
    
    
    
}



struct ScheduleTweetResponse: Codable {
    
    let message: String
}


struct Message: Identifiable {
    enum MessageType {
        case text(String)
        case image([UIImage])
        case voice(URL)
    }
    
    let id: UUID
    let type: MessageType
    let sender: SenderType
}

enum SenderType {
    case user
    case assistant
}

struct ChatResponse: Codable {
    let text: String?
    let images: [String]?
}

struct ChatResponsefromImageApi: Codable {
    let response: String
    
}

struct TranscriptionResponse: Codable {
    let transcription: String
}




















/*
 See LICENSE folder for this sample’s licensing information.
 */

import Foundation
import AVFoundation
import Speech
import Observation

/// A helper for transcribing speech to text using SFSpeechRecognizer and AVAudioEngine.
public actor SpeechRecognizer: Observable {
    public enum RecognizerError: Error {
        case nilRecognizer
        case notAuthorizedToRecognize
        case notPermittedToRecord
        case recognizerIsUnavailable
        
        public var message: String {
            switch self {
            case .nilRecognizer: return "Can't initialize speech recognizer"
            case .notAuthorizedToRecognize: return "Not authorized to recognize speech"
            case .notPermittedToRecord: return "Not permitted to record audio"
            case .recognizerIsUnavailable: return "Recognizer is unavailable"
            }
        }
    }
    
    @MainActor public var transcript: String = ""
    
    private var audioEngine: AVAudioEngine?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?
    
    /**
     Initializes a new speech recognizer. If this is the first time you've used the class, it
     requests access to the speech recognizer and the microphone.
     */
    public init() {
        recognizer = SFSpeechRecognizer()
        guard recognizer != nil else {
            transcribe(RecognizerError.nilRecognizer)
            return
        }
        
        Task {
            do {
                guard await SFSpeechRecognizer.hasAuthorizationToRecognize() else {
                    throw RecognizerError.notAuthorizedToRecognize
                }
                guard await AVAudioSession.sharedInstance().hasPermissionToRecord() else {
                    throw RecognizerError.notPermittedToRecord
                }
            } catch {
                transcribe(error)
            }
        }
    }
    
    @MainActor public func startTranscribing() {
        Task {
            await transcribe()
        }
    }
    
    @MainActor public func resetTranscript() {
        Task {
            await reset()
        }
    }
    
    @MainActor public func stopTranscribing() {
        Task {
            await reset()
        }
    }
    
    /**
     Begin transcribing audio.
     
     Creates a `SFSpeechRecognitionTask` that transcribes speech to text until you call `stopTranscribing()`.
     The resulting transcription is continuously written to the published `transcript` property.
     */
    private func transcribe() {
        guard let recognizer, recognizer.isAvailable else {
            self.transcribe(RecognizerError.recognizerIsUnavailable)
            return
        }
        
        do {
            let (audioEngine, request) = try Self.prepareEngine()
            self.audioEngine = audioEngine
            self.request = request
            self.task = recognizer.recognitionTask(with: request, resultHandler: { [weak self] result, error in
                self?.recognitionHandler(audioEngine: audioEngine, result: result, error: error)
            })
        } catch {
            self.reset()
            self.transcribe(error)
        }
    }
    
    /// Reset the speech recognizer.
    private func reset() {
        task?.cancel()
        audioEngine?.stop()
        audioEngine = nil
        request = nil
        task = nil
    }
    
    private static func prepareEngine() throws -> (AVAudioEngine, SFSpeechAudioBufferRecognitionRequest) {
        let audioEngine = AVAudioEngine()
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        let inputNode = audioEngine.inputNode
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer: AVAudioPCMBuffer, when: AVAudioTime) in
            request.append(buffer)
        }
        audioEngine.prepare()
        try audioEngine.start()
        
        return (audioEngine, request)
    }
    
    nonisolated private func recognitionHandler(audioEngine: AVAudioEngine, result: SFSpeechRecognitionResult?, error: Error?) {
        let receivedFinalResult = result?.isFinal ?? false
        let receivedError = error != nil
        
        if receivedFinalResult || receivedError {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        if let result {
            transcribe(result.bestTranscription.formattedString)
        }
    }
    
    
    nonisolated private func transcribe(_ message: String) {
        Task { @MainActor in
            transcript = message
        }
    }
    nonisolated private func transcribe(_ error: Error) {
        var errorMessage = ""
        if let error = error as? RecognizerError {
            errorMessage += error.message
        } else {
            errorMessage += error.localizedDescription
        }
        Task { @MainActor [errorMessage] in
            transcript = "<< \(errorMessage) >>"
        }
    }
}

extension SFSpeechRecognizer {
    static func hasAuthorizationToRecognize() async -> Bool {
        await withCheckedContinuation { continuation in
            requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
}

extension AVAudioSession {
    func hasPermissionToRecord() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { authorized in
                continuation.resume(returning: authorized)
            }
        }
    }
}
































struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String
    
    func body(content: Content) -> some View {
        ZStack {
            content
            if isShowing {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(message)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(10)
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .transition(.move(edge: .bottom))
                .animation(.easeInOut, value: isShowing)
            }
        }
    }
}


extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message))
    }
}






//-----------------------------------------------------------------------------------
struct UserAIChatView: View {
    
    @StateObject private var viewModel = ChatViewModel()
    
    
    @State private var transcribe = SpeechRecognizer()
    @State private var istranscribing: Bool = false
    
    @State private var messages: [Message] = [
        Message(id: UUID(), type: .text("Hi! How can I assist you today?"), sender: .assistant)
    ]
    
    @State private var referencedMessage: Message? = nil
    @State private var showContextMenu = false
    
    
    @State private var userInput: String = ""
    @State private var isImagePickerPresented = false
    @State private var selectedImages: [UIImage] = []
    @State private var isRecording = false
    @State private var recordedAudioURL: URL?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedAudioDuration: TimeInterval = 0.0
    @State private var selectedMessages: Set<UUID> = []
    @State private var enlargedImage: UIImage?
    @State private var showEnlargedImage = false
    
    
    @State private var textViewHeight: CGFloat = 40
    
    var body: some View {
        VStack {
            ScrollViewReader{ proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(
                                message: message,
                                isSelected: viewModel.selectedMessages.contains(message.id),
                                onLongPress: { handleMessageTap(message) },
                                onImageTap: { image in
                                    enlargedImage = image
                                    showEnlargedImage = true
                                },
                                onSwipe: { swipedMessage in
                                    // Handle swipe-to-reply action
                                    print("Swiped message details: \(swipedMessage)")
                                    
                                    // Example: Set referencedMessage for reply UI
                                    referencedMessage = swipedMessage
                                }
                            )
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
                
                
                
            }
            
            
            
            
            VStack {
                if !viewModel.selectedMessages.isEmpty {
                    HStack {
                        Text("\(viewModel.selectedMessages.count) selected")
                            .foregroundColor(.blue)
                        Spacer()
                        Button("Clear Selection") {
                            viewModel.selectedMessages.removeAll()
                        }
                        .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                }
                
                if !viewModel.selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.selectedImages, id: \.self) { image in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .cornerRadius(10)
                                        .clipped()
                                    
                                    Button(action: {
                                        // Remove the image from the array
                                        if let index = viewModel.selectedImages.firstIndex(of: image) {
                                            viewModel.selectedImages.remove(at: index)
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                    .offset(x: 2, y: -2) // Positioning the delete button
                                }
                            }
                        }
                        .padding(.horizontal)
                    }.padding(.vertical)
                }
                
                if let recordedAudioURL = viewModel.recordedAudioURL {
                    HStack {
                        Button(action: playRecordedAudio) {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                        
                        Text(viewModel.recordedAudioDuration == 0 ? "recording..." : "\(viewModel.recordedAudioDuration) sec")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        Button(action: deleteRecordedAudio) {
                            Image(systemName: "trash.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                
                HStack {
                    
                    Button(action: {
                        isImagePickerPresented = true
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .padding(5)
                        
                            .clipShape(Circle())
                    }
                    .padding(2)
                    .sheet(isPresented: $isImagePickerPresented) {
                        MultiImagePicker(images: $viewModel.selectedImages)
                    }
                    
                    
                    //
                    
                    TextEditor(text: $viewModel.userInput)
                    
                    
                    
                        .frame(minHeight: 40, maxHeight: 120)
                        .fixedSize(horizontal: false, vertical: true)
                        .border(Color(UIColor.systemGray6), width: 0.5)
                    
                    
                    
//                    Button(action: toggleRecording) {
//                        Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle")
//                            .font(.title2)
//                            .foregroundColor(isRecording ? .red : .blue)
//                            .padding(2)
//                        
//                            .clipShape(Circle())
//                    }.padding(2)
//                    
                    
                    Button(action:
                        toggletranscribe
                    ) {
                        Image( systemName: istranscribing ? "stop.circle.fill" :"microbe")
                            .font(.title2)
                            .foregroundColor(isRecording ? .red : .blue)
                            .padding(2)
                        
                            .clipShape(Circle())
                    }.padding(2)
                    
                    Button(action: viewModel.sendMessage) {
                        Image(systemName: "arrow.up")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }.padding(2)
                }
                //                .
                .background(Color.clear)            }
            .padding(5)
        }
        //        .navigationTitle("AI Chat")
        .toast(isShowing: $viewModel.isErrorMessage, message: viewModel.errorMessage ?? "error loading accounts")
        
        // Enlarged Image Preview Overlay
        .overlay(
            Group {
                if showEnlargedImage, let image = enlargedImage {
                    EnlargedImagePreview(image: image, isPresented: $showEnlargedImage)
                }
            }
        )
    }
    
    
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message))
    }
    
    
    private func deleteRecordedAudio() {
        viewModel.recordedAudioURL = nil
        viewModel.recordedAudioDuration = 0.0
    }
    
    
    
    private func handleMessageTap(_ message: Message) {
        if viewModel.selectedMessages.contains(message.id) {
            viewModel.selectedMessages.remove(message.id)
        } else {
            viewModel.selectedMessages.insert(message.id)
            //            print(viewModel.selectedMessages)
            //            print(extractMessagesContentAsData(by: Array(viewModel.selectedMessages), from: viewModel.messages))
        }
    }
    
    
    
    private func sendMessage() {
        
        
        
        
    }
    
    private func toggletranscribe(){
        
        istranscribing.toggle()
        if istranscribing{
            
            transcribe.startTranscribing()
            
        }else{
            transcribe.stopTranscribing()
            viewModel.userInput = transcribe.transcript
            viewModel.sendMessage()
            print(transcribe.transcript)
        }
    }
    
    private func toggleRecording() {
        isRecording.toggle()
        if isRecording {
            startRecording()
        } else {
            stopRecording()
        }
    }
    
    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let audioFilename = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")
            
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            self.viewModel.recordedAudioURL = audioFilename
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false)
            if let url = viewModel.recordedAudioURL {
                let audioPlayer = try AVAudioPlayer(contentsOf: url)
                viewModel.recordedAudioDuration = audioPlayer.duration // Store duration
            }
        } catch {
            print("Failed to stop recording: \(error.localizedDescription)")
        }
    }
    
    private func playRecordedAudio() {
        guard let recordedAudioURL = viewModel.recordedAudioURL else { return }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: recordedAudioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play audio: \(error.localizedDescription)")
        }
    }
}
// ---------------------------------------------

struct MessageBubble: View {
    let message: Message
    let isSelected: Bool
    let onLongPress: () -> Void
    let onImageTap: (UIImage) -> Void
    let onSwipe: (Message) -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var showReplyIndicator = false
    
    var body: some View {
        HStack {
            if message.sender == .assistant {
                Spacer(minLength: 20)
            }
            
            if showReplyIndicator {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .foregroundColor(.gray)
                    .transition(.scale)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                switch message.type {
                case .text(let content):
                    Text(content)
                        .padding()
                        .background(
                            message.sender == .user
                            ? (isSelected ? Color.blue.opacity(0.7) : Color.blue)
                            : (isSelected ? Color.gray.opacity(0.4) : Color.gray.opacity(0.2))
                        )
                        .foregroundColor(message.sender == .user ? .white : .black)
                        .cornerRadius(16)
                        .simultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    handleDragChange(value: value)
                                }
                                .onEnded { value in
                                    handleDragEnd(value: value)
                                }
                        )
                    
                case .image(let image):
                    
                    if message.sender == .user {
                        //                        GroupedImageView(images: image)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                            ForEach(image, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .cornerRadius(10)
                                    .clipped()
                                    .onTapGesture { onImageTap(image) }
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                                    )
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { value in
                                                handleDragChange(value: value)
                                            }
                                            .onEnded { value in
                                                handleDragEnd(value: value)
                                            }
                                    )
                            }
                        }.padding(.trailing, 5)
                        
                    }else{
                        ForEach(image, id: \.self) { image in
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 200, height: 200)
                                .cornerRadius(10)
                                .onTapGesture { onImageTap(image) }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .simultaneousGesture(
                                    DragGesture()
                                        .onChanged { value in
                                            handleDragChange(value: value)
                                        }
                                        .onEnded { value in
                                            handleDragEnd(value: value)
                                        }
                                )
                        }
                        
                    }
                    
                    
                    
                case .voice(let audioURL):
                    HStack {
                        Image(systemName: "waveform.circle.fill")
                            .foregroundColor(.blue)
                        Text("Voice Message")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(
                        isSelected ? Color(UIColor.systemGray5) : Color(UIColor.systemGray6)
                    )
                    .cornerRadius(16)
                    
                    Button(action: onLongPress) {
                        Image(systemName: isSelected ? "star.fill" : "star")
                            .foregroundColor(isSelected ? .yellow : .gray)
                            .padding(4)
                            .background(Color.white.opacity(0.9))
                            .clipShape(Circle())
                    }
                    .offset(x: -8, y: -8)
                }
            }
            //            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: 0.3, perform: onLongPress)
            
            if message.sender == .user {
                Spacer(minLength: 20)
            }
        }
    }
    
    
    // Separate function for handling drag change
    private func handleDragChange(value: DragGesture.Value) {
        if value.translation.width > 20 {
            offsetX = value.translation.width
        }
    }
    
    // Separate function for handling drag end
    private func handleDragEnd(value: DragGesture.Value) {
        if value.translation.width > 50 {
            withAnimation {
                showReplyIndicator = true
                onSwipe(message)
            }
            resetSwipeState()
        } else {
            withAnimation {
                offsetX = 0
            }
        }
    }
    
    // Reset state after a delay
    private func resetSwipeState() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showReplyIndicator = false
                offsetX = 0
            }
        }
    }
}

struct GroupedImageView: View {
    let images: [UIImage]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                ForEach(images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .clipped()
                }
            }.padding(.trailing, 5)
        }
        .padding(8)
        .background(Color.white) // Optional: Add a subtle white background
        .cornerRadius(12)
        //        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)  Optional: Add a light shadow
    }
}


struct EnlargedImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: geometry.size.width)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { scale in
                                    // Handle zoom if needed
                                }
                        )
                }
            }
            .navigationBarItems(
                trailing: Button("Done") {
                    isPresented = false
                }
            )
        }
    }
}



struct EnlargedImagePreview: View {
    let image: UIImage
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: UIScreen.main.bounds.width, maxHeight: UIScreen.main.bounds.height * 0.8)
                    .cornerRadius(12)
                
                Spacer()
                
                Button(action: {
                    isPresented = false
                }) {
                    Text("Dismiss")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                .padding(.bottom, 20)
            }
        }
    }
}



struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var images: [UIImage]
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { (image, error) in
                        if let uiImage = image as? UIImage {
                            DispatchQueue.main.async {
                                self.parent.images.append(uiImage)
                            }
                        } else if let error = error {
                            print("Error loading image: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
}

//struct ContentView: View {
//    var body: some View {
//        TabView {
//            UserAIChatView().tabItem { Label("Chat", systemImage: "message") }
//            AccountsView().tabItem { Label("Socials", systemImage: "person") }
//            AuthView().tabItem { Label("Auth", systemImage: "lock") }
//
//        }
//    }
//}






struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var userEmail = ""
    @State private var userId = ""
    
    
    var body: some View {
        if isAuthenticated {
            
            
            
            // Authenticated Tab View
            TabView {
                UserAIChatView()
                    .tabItem { Label("Chat", systemImage: "message") }
                
                AccountsView()
                    .tabItem { Label("Socials", systemImage: "opticaldisc.fill") }
                
                MediaPostViewer().tabItem { Label("Media", systemImage: "pc") }
                
                
                UserProfileView(email: userEmail, userId: userId, onLogout: {
                    
                    DispatchQueue.main.async {
                        CoreDataManager.shared.clearAllData()
                        isAuthenticated = false
                        deleteFromKeychain(key: "accessToken")
                        deleteFromKeychain(key: "refreshToken")
                        
                    }
                    
                })
                .tabViewStyle(.automatic)
                .toolbarBackground(Color.white, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .tabItem { Label("Profile", systemImage: "person") }
                
                
                
                
            }  .onAppear {
                laoduserprofile()
            }
            
            
            
            
        } else {
            // Unauthenticated Auth View
            AuthView(isAuthenticated: $isAuthenticated)
        }
        
        
    }
    
    
    init() {
        // Check if access token exists in Keychain
        isAuthenticated = getFromKeychain(key: "accessToken") != nil
        
        if let user = CoreDataManager.shared.fetchUser() {
            userEmail = user.email ?? "No Email"
            userId = user.id ?? "No User ID"
        }
    }
    
    
    func laoduserprofile() {
        if let user = CoreDataManager.shared.fetchUser() {
            userEmail = user.email ?? "No Email"
            userId = user.id ?? "No User ID"
        }
    }
    
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess, let data = dataTypeRef as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess {
            print("Keychain item deleted successfully for key: \(key)")
        } else {
            print("Failed to delete keychain item for key: \(key), status: \(status)")
        }
    }
}


#Preview {
    ContentView()
}

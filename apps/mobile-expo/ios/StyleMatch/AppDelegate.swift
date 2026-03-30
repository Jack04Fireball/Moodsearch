import UIKit
import SwiftUI
import AuthenticationServices

enum StyleTheme {
  static let titleFontName = "HelveticaLT-Bold2"
  static let bodyFontName = "Unica77LL-Regular"

  // Swiss-style palette: black field, white type, restrained neutral placeholders.
  static let bg = Color.black
  static let surface = Color.black
  static let surfaceAlt = Color.black
  static let border = Color.white.opacity(0.28)
  static let placeholder = Color(red: 0.35, green: 0.35, blue: 0.35)

  static let textPrimary = Color.white
  static let textSecondary = Color(red: 0.82, green: 0.82, blue: 0.82)
  static let textTertiary = Color(red: 0.66, green: 0.66, blue: 0.66)
  static let badgeNeutral = Color(red: 0.90, green: 0.90, blue: 0.90)

  static let accent = Color.white
  static let accentBright = Color.white
  static let accentGradient = LinearGradient(
    colors: [Color.white, Color.white],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
  static let h1Gradient = LinearGradient(
    colors: [Color.white, Color.white],
    startPoint: .leading,
    endPoint: .trailing
  )

  // Compatibility aliases for existing view code.
  static let bgGradient = LinearGradient(colors: [bg, bg], startPoint: .top, endPoint: .bottom)
  static let surfaceGradient = LinearGradient(colors: [surface, surface], startPoint: .top, endPoint: .bottom)
  static let surfaceAltGradient = LinearGradient(colors: [surfaceAlt, surfaceAlt], startPoint: .top, endPoint: .bottom)
  static let borderGradient = LinearGradient(colors: [border, border], startPoint: .leading, endPoint: .trailing)
  static let ctaGradient = accentGradient
  static let blackCTA = surfaceAlt

  // Typography tuning
  static let posterH1Size: CGFloat = 120
  static let posterH1LineSpacing: CGFloat = 2
  static let sectionH1Size: CGFloat = 70
  static let sectionH1LineSpacing: CGFloat = 1
  static let appHeaderH1Size: CGFloat = 96

  static func titleFont(_ size: CGFloat) -> Font {
    if UIFont(name: titleFontName, size: size) != nil {
      return .custom(titleFontName, size: size)
    }
    return .system(size: size, weight: .bold, design: .default)
  }

  static func bodyFont(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
    if UIFont(name: bodyFontName, size: size) != nil {
      return .custom(bodyFontName, size: size)
    }
    return .system(size: size, weight: weight, design: .default)
  }

  static let dashedStroke = StrokeStyle(lineWidth: 1)
}

struct NoiseOverlay: View {
  var body: some View {
    Color.clear
    .allowsHitTesting(false)
  }
}

struct PunkTextureModifier: ViewModifier {
  let opacity: Double

  func body(content: Content) -> some View {
    content
  }
}

extension View {
  func punkTexture(_ opacity: Double = 0.34) -> some View {
    modifier(PunkTextureModifier(opacity: opacity))
  }
}

final class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    guard
      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first
    else {
      return ASPresentationAnchor()
    }
    return window
  }
}

enum SetupStep {
  case intro1
  case intro2
  case intro3
  case login
  case boards
  case done
}

enum MainTab: Hashable {
  case home
  case moodboards
  case archive
}

struct Moodboard: Identifiable, Hashable {
  let id: UUID
  let name: String
  let coverImageURL: String
  let pinImageURLs: [String]
}

struct Product: Identifiable, Hashable {
  let id: UUID
  let boardID: UUID
  let title: String
  let productImageURL: String
  let brand: String
  let designer: String
  let priceCHF: Int
  let shop: String
  let isNew: Bool
  let recencyBoost: Int
}

struct WireframeImageBlock: View {
  let width: CGFloat?
  let height: CGFloat
  var label: String = "Image"

  init(width: CGFloat? = nil, height: CGFloat, label: String = "Image") {
    self.width = width
    self.height = height
    self.label = label
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(StyleTheme.placeholder)

      VStack(spacing: 4) {
        Image(systemName: "photo")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(StyleTheme.textTertiary)
        Text(label)
          .font(StyleTheme.bodyFont(10))
          .foregroundStyle(StyleTheme.textTertiary)
      }
    }
    .frame(width: width, height: height)
    .clipShape(Rectangle())
    .punkTexture(0.18)
  }
}

struct SwipeableCard<Content: View>: View {
  let onTap: () -> Void
  let onSwipeLeft: () -> Void
  let onSwipeRight: () -> Void
  @ViewBuilder let content: () -> Content

  @State private var dragOffset: CGFloat = 0

  private var leftSwipeProgress: CGFloat {
    min(1, max(0, -dragOffset / 90))
  }

  private var rightSwipeProgress: CGFloat {
    min(1, max(0, dragOffset / 90))
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(Color.black.opacity(max(leftSwipeProgress, rightSwipeProgress)))

      HStack {
        Image(systemName: "hand.thumbsup.fill")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.white)
          .opacity(rightSwipeProgress)
        Spacer()
        Image(systemName: "archivebox.fill")
          .font(.system(size: 22, weight: .semibold))
          .foregroundStyle(.white)
          .opacity(leftSwipeProgress)
      }
      .padding(.horizontal, 18)

      content()
        .offset(x: dragOffset)
        .simultaneousGesture(
          TapGesture().onEnded {
            onTap()
          }
        )
        .gesture(
          DragGesture(minimumDistance: 16)
            .onChanged { value in
              dragOffset = max(-120, min(120, value.translation.width))
            }
            .onEnded { value in
              if value.translation.width <= -80 {
                onSwipeLeft()
              } else if value.translation.width >= 80 {
                onSwipeRight()
              }
              withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                dragOffset = 0
              }
            }
        )
    }
    .clipShape(Rectangle())
  }
}

final class PrototypeStore: ObservableObject {
  @Published var setupStep: SetupStep = .intro1
  @Published var mainTab: MainTab = .home

  @Published var boardSearch: String = ""
  @Published var selectedBoardIDs: Set<UUID> = []

  @Published var sizeProfile: String = "M"
  @Published var selectedBrandFocus: Set<String> = []
  @Published var priceMin: Double = 200
  @Published var priceMax: Double = 2000

  @Published var moodboardDesignerFocus: [UUID: Set<String>] = [:]
  @Published var customDesignersByBoard: [UUID: [String]] = [:]
  @Published var moodboardBrandFocus: [UUID: Set<String>] = [:]
  @Published var customBrandsByBoard: [UUID: [String]] = [:]
  @Published var moodboardPriceMin: [UUID: Double] = [:]
  @Published var moodboardPriceMax: [UUID: Double] = [:]
  @Published var moodboardQualityFocus: [UUID: Set<String>] = [:]
  @Published var moodboardCountryFocus: [UUID: Set<String>] = [:]

  @Published var activeBoardFilter: UUID? = nil
  @Published var selectedProduct: Product? = nil
  @Published var selectedMoodboard: Moodboard? = nil

  @Published var archivedProductIDs: Set<UUID> = []
  @Published var boughtProductIDs: Set<UUID> = []
  @Published var likedProductIDs: Set<UUID> = []
  @Published var dislikedProductIDs: Set<UUID> = []
  @Published var hasAcceptedCompliance: Bool = false
  @Published var pinterestConnectedUsername: String? = nil
  @Published var pinterestAuthError: String? = nil
  @Published var isPinterestConnecting: Bool = false

  let availableDesigners: [String]
  let availableBrands: [String]
  let availableQualities: [String]
  let availableCountries: [String]
  let allBoards: [Moodboard]
  let allProducts: [Product]
  private let apiBaseURL: String
  private let authPresentationContext = AuthPresentationContextProvider()
  private var authSession: ASWebAuthenticationSession?

  init() {
    self.apiBaseURL = (Bundle.main.object(forInfoDictionaryKey: "StyleMatchAPIBaseURL") as? String) ?? "http://10.5.8.80:4000"
    self.availableDesigners = [
      "Rick Owens", "Maison Margiela", "Acne Studios", "Helmut Lang", "Jil Sander",
      "Prada", "Lemaire", "Our Legacy", "Ami Paris", "Yohji Yamamoto"
    ]

    self.availableBrands = [
      "Arket", "COS", "Uniqlo", "Massimo Dutti", "Zalando",
      "Weekday", "Nudie Jeans", "A.P.C.", "Carhartt WIP", "Norse Projects"
    ]
    self.availableQualities = ["Premium", "Mid-range", "Budget", "Handmade", "Sustainable"]
    self.availableCountries = ["Italy", "France", "Japan", "Portugal", "Switzerland", "Germany", "UK", "USA"]

    let boards = [
      Moodboard(
        id: UUID(),
        name: "Minimal Outfits",
        coverImageURL: "https://images.unsplash.com/photo-1483985988355-763728e1935b?w=1200",
        pinImageURLs: [
          "https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?w=800",
          "https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=800",
          "https://images.unsplash.com/photo-1485968579580-b6d095142e6e?w=800"
        ]
      ),
      Moodboard(
        id: UUID(),
        name: "Streetwear Looks",
        coverImageURL: "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=1200",
        pinImageURLs: [
          "https://images.unsplash.com/photo-1495121605193-b116b5b09a6b?w=800",
          "https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=800",
          "https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=800"
        ]
      ),
      Moodboard(
        id: UUID(),
        name: "Tailored Essentials",
        coverImageURL: "https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=1200",
        pinImageURLs: [
          "https://images.unsplash.com/photo-1552374196-c4e7ffc6e126?w=800",
          "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=800",
          "https://images.unsplash.com/photo-1445205170230-053b83016050?w=800"
        ]
      ),
      Moodboard(
        id: UUID(),
        name: "Neutral Winter Fits",
        coverImageURL: "https://images.unsplash.com/photo-1512436991641-6745cdb1723f?w=1200",
        pinImageURLs: [
          "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=800",
          "https://images.unsplash.com/photo-1529139574466-a303027c1d8b?w=800",
          "https://images.unsplash.com/photo-1485230895905-ec40ba36b9bc?w=800"
        ]
      ),
      Moodboard(
        id: UUID(),
        name: "Sneaker Rotation",
        coverImageURL: "https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=1200",
        pinImageURLs: [
          "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=800",
          "https://images.unsplash.com/photo-1600185365483-26d7a4cc7519?w=800",
          "https://images.unsplash.com/photo-1556048219-bb6978360b84?w=800"
        ]
      )
    ]

    self.allBoards = boards
    self.selectedBoardIDs = Set(boards.map(\.id))

    self.allProducts = [
      Product(id: UUID(), boardID: boards[0].id, title: "Wool Overshirt", productImageURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=1000", brand: "Arket", designer: "Jil Sander", priceCHF: 320, shop: "Arket", isNew: true, recencyBoost: 95),
      Product(id: UUID(), boardID: boards[1].id, title: "Relaxed Cargo Pant", productImageURL: "https://images.unsplash.com/photo-1473966968600-fa801b869a1a?w=1000", brand: "COS", designer: "Our Legacy", priceCHF: 420, shop: "COS", isNew: true, recencyBoost: 92),
      Product(id: UUID(), boardID: boards[2].id, title: "Structured Blazer", productImageURL: "https://images.unsplash.com/photo-1594938298603-c8148c4dae35?w=1000", brand: "Massimo Dutti", designer: "Lemaire", priceCHF: 790, shop: "Massimo Dutti", isNew: true, recencyBoost: 88),
      Product(id: UUID(), boardID: boards[3].id, title: "Merino Turtleneck", productImageURL: "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=1000", brand: "Uniqlo", designer: "Helmut Lang", priceCHF: 260, shop: "Uniqlo", isNew: true, recencyBoost: 85),
      Product(id: UUID(), boardID: boards[4].id, title: "Retro Sneaker", productImageURL: "https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=1000", brand: "Zalando", designer: "Prada", priceCHF: 680, shop: "Zalando", isNew: true, recencyBoost: 83),
      Product(id: UUID(), boardID: boards[0].id, title: "Boxy Tee", productImageURL: "https://images.unsplash.com/photo-1527719327859-c6ce80353573?w=1000", brand: "Weekday", designer: "Acne Studios", priceCHF: 210, shop: "Weekday", isNew: true, recencyBoost: 80),
      Product(id: UUID(), boardID: boards[2].id, title: "Pleated Trouser", productImageURL: "https://images.unsplash.com/photo-1506629905607-d9f9fc8f4f74?w=1000", brand: "A.P.C.", designer: "Maison Margiela", priceCHF: 560, shop: "A.P.C.", isNew: true, recencyBoost: 78),
      Product(id: UUID(), boardID: boards[1].id, title: "Tech Shell Jacket", productImageURL: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=1000", brand: "Carhartt WIP", designer: "Yohji Yamamoto", priceCHF: 640, shop: "Carhartt WIP", isNew: true, recencyBoost: 76)
    ]
  }

  var filteredBoards: [Moodboard] {
    let trimmed = boardSearch.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return allBoards
    }
    return allBoards.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
  }

  var selectedBoards: [Moodboard] {
    allBoards.filter { selectedBoardIDs.contains($0.id) }
  }

  var visibleBoardsForTabs: [Moodboard] {
    let base = selectedBoards
    if let activeBoardFilter {
      return base.filter { $0.id == activeBoardFilter }
    }
    return base
  }

  var moodboardsOverviewBoards: [Moodboard] {
    selectedBoards
  }

  var homeProducts: [Product] {
    let candidates = allProducts.filter { product in
      guard selectedBoardIDs.contains(product.boardID) else { return false }
      guard product.isNew else { return false }

      if let activeBoardFilter, product.boardID != activeBoardFilter {
        return false
      }

      let price = Double(product.priceCHF)
      if price < priceMin || price > priceMax {
        return false
      }

      return true
    }

    return candidates.sorted { score(for: $0) > score(for: $1) }
  }

  func score(for product: Product) -> Int {
    var total = product.recencyBoost

    if selectedBrandFocus.contains(product.brand) {
      total += 22
    }
    let boardBrandFocus = moodboardBrandFocus[product.boardID] ?? []
    if boardBrandFocus.contains(product.brand) {
      total += 24
    }

    let boardDesignerFocus = moodboardDesignerFocus[product.boardID] ?? []
    if boardDesignerFocus.contains(product.designer) {
      total += 30
    }

    return total
  }

  func introText() -> String {
    switch setupStep {
    case .intro1:
      return "Find products that match your Pinterest style."
    case .intro2:
      return "Use moodboard-based focus to guide results."
    case .intro3:
      return "Open the best matches and buy faster."
    default:
      return ""
    }
  }

  func introTitle() -> String {
    switch setupStep {
    case .intro1:
      return "Intro 1/3"
    case .intro2:
      return "Intro 2/3"
    case .intro3:
      return "Intro 3/3"
    default:
      return ""
    }
  }

  func nextIntroStep() {
    switch setupStep {
    case .intro1:
      setupStep = .intro2
    case .intro2:
      setupStep = .intro3
    case .intro3:
      setupStep = .login
    default:
      break
    }
  }

  func connectPinterest() {
    let redirectURI = "stylematch://auth"
    guard let encodedRedirect = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let authURL = URL(string: "\(apiBaseURL)/v1/auth/pinterest?redirect=\(encodedRedirect)") else {
      pinterestAuthError = "Pinterest login configuration is invalid."
      return
    }

    pinterestAuthError = nil
    isPinterestConnecting = true

    let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: "stylematch") { [weak self] callbackURL, error in
      DispatchQueue.main.async {
        guard let self else { return }
        self.isPinterestConnecting = false

        if let error {
          self.pinterestAuthError = "Pinterest login failed: \(error.localizedDescription)"
          return
        }

        guard let callbackURL else {
          self.pinterestAuthError = "No callback URL was returned."
          return
        }

        let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        let token = items.first(where: { $0.name == "token" })?.value ?? ""
        let username = items.first(where: { $0.name == "username" })?.value
        let errorMessage = items.first(where: { $0.name == "error" })?.value

        if !token.isEmpty {
          self.pinterestConnectedUsername = username
          self.pinterestAuthError = nil
          self.setupStep = .boards
        } else {
          self.pinterestAuthError = errorMessage ?? "Pinterest callback did not include a token."
        }
      }
    }

    session.presentationContextProvider = authPresentationContext
    session.prefersEphemeralWebBrowserSession = false
    authSession = session

    if !session.start() {
      isPinterestConnecting = false
      pinterestAuthError = "Could not open Pinterest login."
    }
  }

  func continueWithoutPinterest() {
    pinterestAuthError = nil
    setupStep = .boards
  }

  func toggleBoard(_ board: Moodboard) {
    if selectedBoardIDs.contains(board.id) {
      selectedBoardIDs.remove(board.id)
      if activeBoardFilter == board.id {
        activeBoardFilter = nil
      }
      return
    }

    if selectedBoardIDs.count >= 10 {
      return
    }

    selectedBoardIDs.insert(board.id)
  }

  func continueFromBoards() {
    if selectedBoardIDs.count >= 1 {
      setupStep = .done
    }
  }

  func resetAll() {
    setupStep = .intro1
    mainTab = .home
    boardSearch = ""
    selectedBoardIDs = []
    sizeProfile = "M"
    selectedBrandFocus = []
    priceMin = 200
    priceMax = 2000
    moodboardDesignerFocus = [:]
    customDesignersByBoard = [:]
    moodboardBrandFocus = [:]
    customBrandsByBoard = [:]
    moodboardPriceMin = [:]
    moodboardPriceMax = [:]
    moodboardQualityFocus = [:]
    moodboardCountryFocus = [:]
    activeBoardFilter = nil
    selectedProduct = nil
    selectedMoodboard = nil
    archivedProductIDs = []
    boughtProductIDs = []
    likedProductIDs = []
    dislikedProductIDs = []
    hasAcceptedCompliance = false
    pinterestConnectedUsername = nil
    pinterestAuthError = nil
    isPinterestConnecting = false
  }

  func acknowledgeCompliance() {
    hasAcceptedCompliance = true
  }

  var complianceRules: [String] {
    [
      "Only use Pinterest data for the authorized user who connected the account.",
      "Do not store Pinterest API data permanently (except your campaign analytics).",
      "No scraping, no automated bulk actions, no hidden actions on behalf of users.",
      "Do not combine Pinterest data with personal data from other services.",
      "Do not sell or share Pinterest data with third parties.",
      "Use API credentials securely and report data breaches quickly."
    ]
  }

  func boardName(for boardID: UUID) -> String {
    allBoards.first(where: { $0.id == boardID })?.name ?? "Unknown Board"
  }

  func archivedProducts(for board: Moodboard) -> [Product] {
    allProducts.filter { archivedProductIDs.contains($0.id) && $0.boardID == board.id }
  }

  func boughtProducts(for board: Moodboard) -> [Product] {
    allProducts.filter { boughtProductIDs.contains($0.id) && $0.boardID == board.id }
  }

  func toggleArchive(_ product: Product) {
    if archivedProductIDs.contains(product.id) {
      archivedProductIDs.remove(product.id)
    } else {
      archivedProductIDs.insert(product.id)
      likedProductIDs.remove(product.id)
      dislikedProductIDs.remove(product.id)
    }
  }

  func archiveFromHomeSwipe(_ product: Product) {
    archivedProductIDs.insert(product.id)
    likedProductIDs.remove(product.id)
    dislikedProductIDs.remove(product.id)
  }

  func likeFromHomeSwipe(_ product: Product) {
    likedProductIDs.insert(product.id)
    archivedProductIDs.remove(product.id)
    dislikedProductIDs.remove(product.id)
  }

  func toggleLike(_ product: Product) {
    if likedProductIDs.contains(product.id) {
      likedProductIDs.remove(product.id)
      return
    }
    likedProductIDs.insert(product.id)
    dislikedProductIDs.remove(product.id)
  }

  func toggleDislike(_ product: Product) {
    if dislikedProductIDs.contains(product.id) {
      dislikedProductIDs.remove(product.id)
      return
    }
    dislikedProductIDs.insert(product.id)
    likedProductIDs.remove(product.id)
  }

  func toggleBought(_ product: Product) {
    if boughtProductIDs.contains(product.id) {
      boughtProductIDs.remove(product.id)
    } else {
      boughtProductIDs.insert(product.id)
    }
  }

  var archivedProductsForCurrentFilter: [Product] {
    allProducts.filter { product in
      guard archivedProductIDs.contains(product.id) else { return false }
      guard selectedBoardIDs.contains(product.boardID) else { return false }
      if let activeBoardFilter, product.boardID != activeBoardFilter {
        return false
      }
      return true
    }
    .sorted { score(for: $0) > score(for: $1) }
  }

  func toggleBrandFocus(_ name: String) {
    if selectedBrandFocus.contains(name) {
      selectedBrandFocus.remove(name)
    } else {
      selectedBrandFocus.insert(name)
    }
  }

  func designerFocus(for boardID: UUID) -> Set<String> {
    moodboardDesignerFocus[boardID] ?? []
  }

  func toggleDesignerFocus(for boardID: UUID, designer: String) {
    var current = moodboardDesignerFocus[boardID] ?? []

    if current.contains(designer) {
      current.remove(designer)
    } else {
      current.insert(designer)
    }

    moodboardDesignerFocus[boardID] = current
  }

  func addCustomDesigner(for boardID: UUID, name: String) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    var current = customDesignersByBoard[boardID] ?? []
    let alreadyExists = current.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    if !alreadyExists {
      current.append(trimmed)
      customDesignersByBoard[boardID] = current
    }
  }

  func suggestedDesigners(for board: Moodboard) -> [String] {
    if board.name.contains("Street") {
      return ["Our Legacy", "Yohji Yamamoto", "Acne Studios", "Rick Owens"]
    }

    if board.name.contains("Tailored") {
      return ["Lemaire", "Jil Sander", "Prada", "Maison Margiela"]
    }

    if board.name.contains("Sneaker") {
      return ["Prada", "Acne Studios", "Our Legacy", "Rick Owens"]
    }

    return ["Jil Sander", "Helmut Lang", "Acne Studios", "Lemaire"]
  }

  func designersForBoard(_ board: Moodboard) -> [String] {
    let base = suggestedDesigners(for: board)
    let custom = customDesignersByBoard[board.id] ?? []
    return Array(Set(base + custom)).sorted()
  }

  func addCustomBrand(for boardID: UUID, name: String) {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    var current = customBrandsByBoard[boardID] ?? []
    let alreadyExists = current.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    if !alreadyExists {
      current.append(trimmed)
      customBrandsByBoard[boardID] = current
    }
  }

  func brandsForBoard(_ board: Moodboard) -> [String] {
    let custom = customBrandsByBoard[board.id] ?? []
    return Array(Set(availableBrands + custom)).sorted()
  }

  func brandFocus(for boardID: UUID) -> Set<String> {
    moodboardBrandFocus[boardID] ?? []
  }

  func toggleBrandFocus(for boardID: UUID, brand: String) {
    var current = moodboardBrandFocus[boardID] ?? []
    if current.contains(brand) {
      current.remove(brand)
    } else {
      current.insert(brand)
    }
    moodboardBrandFocus[boardID] = current
  }

  func priceMin(for boardID: UUID) -> Double {
    moodboardPriceMin[boardID] ?? 200
  }

  func priceMax(for boardID: UUID) -> Double {
    moodboardPriceMax[boardID] ?? 2000
  }

  func setPriceMin(for boardID: UUID, value: Double) {
    let clamped = min(value, priceMax(for: boardID))
    moodboardPriceMin[boardID] = clamped
  }

  func setPriceMax(for boardID: UUID, value: Double) {
    let clamped = max(value, priceMin(for: boardID))
    moodboardPriceMax[boardID] = clamped
  }

  func qualityFocus(for boardID: UUID) -> Set<String> {
    moodboardQualityFocus[boardID] ?? []
  }

  func toggleQualityFocus(for boardID: UUID, quality: String) {
    var current = moodboardQualityFocus[boardID] ?? []
    if current.contains(quality) {
      current.remove(quality)
    } else {
      current.insert(quality)
    }
    moodboardQualityFocus[boardID] = current
  }

  func countryFocus(for boardID: UUID) -> Set<String> {
    moodboardCountryFocus[boardID] ?? []
  }

  func toggleCountryFocus(for boardID: UUID, country: String) {
    var current = moodboardCountryFocus[boardID] ?? []
    if current.contains(country) {
      current.remove(country)
    } else {
      current.insert(country)
    }
    moodboardCountryFocus[boardID] = current
  }
}

struct BoardSettingsView: View {
  @ObservedObject var store: PrototypeStore
  let board: Moodboard
  @State private var customDesignerName = ""
  @State private var customBrandName = ""

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Moodboard Settings")
          .font(StyleTheme.titleFont(28))
          .foregroundStyle(StyleTheme.textPrimary)

        Text("Set filters for this moodboard only.")
          .font(StyleTheme.bodyFont(12))
          .foregroundStyle(StyleTheme.textSecondary)

        Text("Brand").font(StyleTheme.titleFont(20))
        HStack {
          TextField("Add brand", text: $customBrandName)
            .font(StyleTheme.bodyFont(14))
            .foregroundStyle(StyleTheme.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled(true)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
              Rectangle().fill(StyleTheme.border).frame(height: 1)
            }
          Button("Add") {
            store.addCustomBrand(for: board.id, name: customBrandName)
            customBrandName = ""
          }
          .font(StyleTheme.titleFont(14))
        }

        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
          ForEach(store.brandsForBoard(board), id: \.self) { brand in
            settingsChip(
              title: brand,
              selected: store.brandFocus(for: board.id).contains(brand)
            ) {
              store.toggleBrandFocus(for: board.id, brand: brand)
            }
          }
        }

        Text("Designer").font(StyleTheme.titleFont(20))
        HStack {
          TextField("Add designer", text: $customDesignerName)
            .font(StyleTheme.bodyFont(14))
            .foregroundStyle(StyleTheme.textPrimary)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled(true)
            .padding(.vertical, 6)
            .overlay(alignment: .bottom) {
              Rectangle().fill(StyleTheme.border).frame(height: 1)
            }
          Button("Add") {
            store.addCustomDesigner(for: board.id, name: customDesignerName)
            customDesignerName = ""
          }
          .font(StyleTheme.titleFont(14))
        }

        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
          ForEach(store.designersForBoard(board), id: \.self) { designer in
            settingsChip(
              title: designer,
              selected: store.designerFocus(for: board.id).contains(designer)
            ) {
              store.toggleDesignerFocus(for: board.id, designer: designer)
            }
          }
        }

        Text("Price").font(StyleTheme.titleFont(20))
        Text("CHF \(Int(store.priceMin(for: board.id))) - \(Int(store.priceMax(for: board.id)))")
          .font(StyleTheme.bodyFont(14, weight: .semibold))
        Text("From")
        Slider(
          value: Binding(
            get: { store.priceMin(for: board.id) },
            set: { store.setPriceMin(for: board.id, value: $0) }
          ),
          in: 0...5000,
          step: 10
        )
        Text("To")
        Slider(
          value: Binding(
            get: { store.priceMax(for: board.id) },
            set: { store.setPriceMax(for: board.id, value: $0) }
          ),
          in: 0...5000,
          step: 10
        )

        Text("Quality").font(StyleTheme.titleFont(20))
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
          ForEach(store.availableQualities, id: \.self) { quality in
            settingsChip(
              title: quality,
              selected: store.qualityFocus(for: board.id).contains(quality)
            ) {
              store.toggleQualityFocus(for: board.id, quality: quality)
            }
          }
        }

        Text("Country of origin").font(StyleTheme.titleFont(20))
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
          ForEach(store.availableCountries, id: \.self) { country in
            settingsChip(
              title: country,
              selected: store.countryFocus(for: board.id).contains(country)
            ) {
              store.toggleCountryFocus(for: board.id, country: country)
            }
          }
        }
    }
    .padding(16)
    }
    .background(StyleTheme.bgGradient)
    .punkTexture(0.28)
  }

  private func settingsChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    return Button(action: action) {
      HStack {
        Text(title)
          .font(StyleTheme.bodyFont(14, weight: selected ? .semibold : .regular))
          .lineLimit(1)
        Spacer()
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
      }
      .padding(10)
      .foregroundStyle(selected ? StyleTheme.textPrimary : StyleTheme.textSecondary)
      .punkTexture(0.24)
    }
    .buttonStyle(.plain)
  }
}

struct BoardDetailView: View {
  @ObservedObject var store: PrototypeStore
  let board: Moodboard
  @State private var pageSelection = 0

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 10) {
          Text("Pinterest liked pins")
            .font(StyleTheme.titleFont(24))
            .foregroundStyle(StyleTheme.textPrimary)
          categoryTabs
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .punkTexture(0.25)

        TabView(selection: $pageSelection) {
          pinsPage
            .tag(0)

          purchasesPage
            .tag(1)

          BoardSettingsView(store: store, board: board)
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
      .navigationTitle(board.name)
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        pageSelection = 0
      }
    }
  }

  private var categoryTabs: some View {
    HStack(spacing: 20) {
      categoryTab(title: "Pins", index: 0)
      categoryTab(title: "Purchases", index: 1)
      categoryTab(title: "Settings", index: 2)
    }
  }

  private func categoryTab(title: String, index: Int) -> some View {
    Button {
      pageSelection = index
    } label: {
      VStack(spacing: 6) {
        Text(title)
          .font(StyleTheme.bodyFont(15, weight: .semibold))
          .foregroundStyle(StyleTheme.textPrimary)
        Rectangle()
          .fill(pageSelection == index ? StyleTheme.accentBright : Color.clear)
          .frame(height: 2)
      }
    }
    .buttonStyle(.plain)
  }

  private var pinsPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Pinterest-like pins")
          .font(StyleTheme.titleFont(22))
          .foregroundStyle(StyleTheme.textPrimary)
        Text("Swipe left for purchases, swipe left again for settings.")
          .font(StyleTheme.bodyFont(12))
          .foregroundStyle(StyleTheme.textSecondary)

        let columns = pinterestColumns()
        HStack(alignment: .top, spacing: 10) {
          VStack(spacing: 10) {
            ForEach(Array(columns.left.enumerated()), id: \.element) { index, url in
              pinCard(url: url, height: pinHeight(index: index, seed: 1))
            }
          }
          VStack(spacing: 10) {
            ForEach(Array(columns.right.enumerated()), id: \.element) { index, url in
              pinCard(url: url, height: pinHeight(index: index, seed: 2))
            }
          }
        }
      }
      .padding(12)
    }
  }

  private var purchasesPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 10) {
        Text("Purchases for this moodboard")
          .font(StyleTheme.titleFont(22))
          .foregroundStyle(StyleTheme.textPrimary)
        let bought = store.boughtProducts(for: board)
        if bought.isEmpty {
          Text("No purchases for this moodboard yet.")
            .foregroundStyle(StyleTheme.textSecondary)
            .padding(.top, 8)
        } else {
          ForEach(bought) { product in
            HStack(spacing: 10) {
              WireframeImageBlock(width: 70, height: 70, label: "Product")

              VStack(alignment: .leading, spacing: 3) {
                Text(product.title).bold()
                  .foregroundStyle(StyleTheme.textPrimary)
                Text("CHF \(product.priceCHF)")
                  .foregroundStyle(StyleTheme.textPrimary)
                Text("\(product.brand) · \(product.designer)")
                  .font(StyleTheme.bodyFont(12))
                  .foregroundStyle(StyleTheme.textSecondary)
              }
              Spacer()
            }
            .padding(10)
            .background(Color.clear)
            .punkTexture(0.24)
          }
        }
      }
      .padding(16)
    }
  }

  private func pinterestColumns() -> (left: [String], right: [String]) {
    var left: [String] = []
    var right: [String] = []

    for (index, url) in board.pinImageURLs.enumerated() {
      if index % 2 == 0 {
        left.append(url)
      } else {
        right.append(url)
      }
    }

    return (left, right)
  }

  private func pinHeight(index: Int, seed: Int) -> CGFloat {
    let heights: [CGFloat] = [170, 220, 260, 190, 240]
    let mapped = (index + seed) % heights.count
    return heights[mapped]
  }

  private func pinCard(url: String, height: CGFloat) -> some View {
    WireframeImageBlock(height: height, label: "Pin")
      .frame(maxWidth: .infinity)
  }
}

struct PrototypeRootView: View {
  @StateObject private var store = PrototypeStore()
  private var isPosterIntroStep: Bool {
    store.setupStep == .intro1 || store.setupStep == .intro2 || store.setupStep == .intro3
  }

  var body: some View {
    NavigationStack {
      ZStack {
        StyleTheme.bgGradient.ignoresSafeArea()

        Group {
          if store.setupStep != .done {
            if isPosterIntroStep {
              setupFlow
            } else {
              ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                  setupFlow
                }
                .padding(16)
              }
            }
          } else {
            appFlow
          }
        }
      }
      .tint(StyleTheme.accentBright)
      .toolbar(.hidden, for: .navigationBar)
      .sheet(item: $store.selectedProduct) { product in
        ProductDetailSheetView(store: store, product: product)
      }
      .sheet(item: $store.selectedMoodboard) { board in
        BoardDetailView(store: store, board: board)
      }
    }
  }

  @ViewBuilder
  private var setupFlow: some View {
    switch store.setupStep {
    case .intro1:
      introPosterScreen(
        posterIndex: "01 / 03",
        title: "CURATE",
        imageLabel: "Intro Poster I",
        description: "Find products that match your Pinterest style and create your own visual direction.",
        actionTitle: "NEXT"
      ) {
        store.nextIntroStep()
      }

    case .intro2:
      introPosterScreen(
        posterIndex: "02 / 03",
        title: "FOCUS",
        imageLabel: "Intro Poster II",
        description: "Use moodboard-based focus so the feed ranks what fits your aesthetic first.",
        actionTitle: "NEXT"
      ) {
        store.nextIntroStep()
      }

    case .intro3:
      introPosterScreen(
        posterIndex: "03 / 03",
        title: "MATCH",
        imageLabel: "Intro Poster III",
        description: "Open high-match offers and move faster from inspiration to buying.",
        actionTitle: "CONTINUE TO LOGIN"
      ) {
        store.nextIntroStep()
      }

    case .login:
      setupHeroSection(
        title: "Pinterest Login",
        imageLabel: "Login",
        description: "Connect your Pinterest account to load your liked pins and selected moodboards."
      )
      if let username = store.pinterestConnectedUsername {
        Text("Connected as \(username)")
          .font(StyleTheme.bodyFont(13, weight: .semibold))
          .foregroundStyle(StyleTheme.textSecondary)
      }
      if let authError = store.pinterestAuthError {
        Text(authError)
          .font(StyleTheme.bodyFont(13))
          .foregroundStyle(StyleTheme.textSecondary)
      }
      if store.isPinterestConnecting {
        ProgressView("Opening Pinterest login...")
          .font(StyleTheme.bodyFont(13))
          .foregroundStyle(StyleTheme.textSecondary)
      }
      Button {
        store.connectPinterest()
      } label: {
        editorialActionLabel(store.isPinterestConnecting ? "Connecting..." : "Connect Pinterest")
      }
      .disabled(store.isPinterestConnecting)
      .buttonStyle(.plain)

      Button {
        store.continueWithoutPinterest()
      } label: {
        editorialActionLabel("Continue without login")
      }
      .buttonStyle(.plain)

    case .boards:
      Text("Select moodboard")
        .font(StyleTheme.titleFont(StyleTheme.sectionH1Size))
        .lineSpacing(StyleTheme.sectionH1LineSpacing)
        .tracking(0.6)
        .lineLimit(2)
        .minimumScaleFactor(0.25)
        .foregroundStyle(StyleTheme.textPrimary)
      TextField("Search board name", text: $store.boardSearch)
        .font(StyleTheme.bodyFont(16))
        .foregroundStyle(StyleTheme.textPrimary)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) {
          Rectangle().fill(StyleTheme.border).frame(height: 1)
        }

      LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
        ForEach(store.filteredBoards) { board in
          let isSelected = store.selectedBoardIDs.contains(board.id)
          Button {
            store.toggleBoard(board)
          } label: {
            VStack(alignment: .leading, spacing: 8) {
              ZStack(alignment: .topTrailing) {
                WireframeImageBlock(height: 162, label: "Moodboard")
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(isSelected ? StyleTheme.accentBright : StyleTheme.textSecondary)
                  .padding(8)
              }

              Text(board.name)
                .font(StyleTheme.bodyFont(14, weight: .semibold))
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.clear)
            .punkTexture(0.3)
          }
          .buttonStyle(.plain)
        }
      }

      Text("Selected: \(store.selectedBoardIDs.count)")
        .foregroundStyle(StyleTheme.textSecondary)
      Button {
        store.continueFromBoards()
      } label: {
        editorialActionLabel("Tap to get started")
          .opacity(store.selectedBoardIDs.isEmpty ? 0.45 : 1.0)
      }
      .disabled(store.selectedBoardIDs.isEmpty)
      .buttonStyle(.plain)
      .frame(maxWidth: .infinity, alignment: .leading)

    case .done:
      EmptyView()
    }
  }

  private func introPosterScreen(
    posterIndex: String,
    title: String,
    imageLabel: String,
    description: String,
    actionTitle: String,
    action: @escaping () -> Void
  ) -> some View {
    GeometryReader { proxy in
      ZStack(alignment: .bottomLeading) {
        WireframeImageBlock(height: proxy.size.height, label: imageLabel)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()

        VStack(alignment: .leading, spacing: 12) {
          Text(posterIndex)
            .font(StyleTheme.bodyFont(12, weight: .semibold))
            .tracking(2.2)
            .foregroundStyle(StyleTheme.textSecondary)

          Text(title)
            .font(StyleTheme.titleFont(StyleTheme.posterH1Size))
            .lineSpacing(StyleTheme.posterH1LineSpacing)
            .tracking(0.9)
            .lineLimit(2)
            .minimumScaleFactor(0.25)
            .foregroundStyle(StyleTheme.h1Gradient)

          Text(description)
            .font(StyleTheme.bodyFont(17))
            .foregroundStyle(StyleTheme.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 4)

          Button {
            action()
          } label: {
            editorialActionLabel(actionTitle)
          }
          .buttonStyle(.plain)
          .padding(.top, 6)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 28)
      }
      .frame(width: proxy.size.width, height: proxy.size.height)
      .punkTexture(0.34)
    }
    .ignoresSafeArea()
  }

  private func editorialActionLabel(_ title: String) -> some View {
    HStack(spacing: 10) {
      Text(title.uppercased())
        .font(StyleTheme.titleFont(20))
        .tracking(1.1)
      Image(systemName: "arrow.right")
        .font(.system(size: 15, weight: .semibold))
    }
    .foregroundStyle(StyleTheme.textPrimary)
  }

  private func setupHeroSection(title: String, imageLabel: String, description: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(StyleTheme.titleFont(StyleTheme.sectionH1Size))
        .lineSpacing(StyleTheme.sectionH1LineSpacing)
        .tracking(0.6)
        .lineLimit(2)
        .minimumScaleFactor(0.25)
        .foregroundStyle(StyleTheme.textPrimary)
      WireframeImageBlock(height: 190, label: imageLabel)
      Text(description)
        .font(StyleTheme.bodyFont(16))
        .foregroundStyle(StyleTheme.textSecondary)
        .lineSpacing(3)
    }
  }

  private var appFlow: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 14, pinnedViews: [.sectionHeaders]) {
        Section {
          VStack(alignment: .leading, spacing: 14) {
            switch store.mainTab {
            case .home:
              homeTab
            case .moodboards:
              moodboardsTab
            case .archive:
              archiveTab
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 0)
          .padding(.bottom, 16)
        } header: {
          stickyTabHeader
        }
      }
    }
  }

  private var stickyTabHeader: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title(for: store.mainTab))
        .font(StyleTheme.titleFont(StyleTheme.appHeaderH1Size))
        .lineSpacing(8)
        .tracking(0.9)
        .lineLimit(1)
        .minimumScaleFactor(0.45)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(StyleTheme.h1Gradient)

      HStack(spacing: 12) {
        ForEach([MainTab.home, MainTab.moodboards, MainTab.archive], id: \.self) { tab in
          secondaryTabButton(tab: tab, isActive: store.mainTab == tab) {
            store.mainTab = tab
          }
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 20)
    .padding(.bottom, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .punkTexture(0.2)
  }

  private func secondaryTabButton(tab: MainTab, isActive: Bool, action: @escaping () -> Void) -> some View {
    return Button(action: action) {
      Text(title(for: tab).uppercased())
        .font(StyleTheme.bodyFont(18, weight: isActive ? .semibold : .regular))
        .tracking(1.1)
        .foregroundStyle(isActive ? StyleTheme.textPrimary : StyleTheme.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 4)
    }
    .buttonStyle(.plain)
  }

  private func title(for tab: MainTab) -> String {
    switch tab {
    case .home:
      return "Home"
    case .moodboards:
      return "Moodboards"
    case .archive:
      return "Archive"
    }
  }

  @ViewBuilder
  private var boardFilterBar: some View {
    Text("Moodboard Filter")
      .font(StyleTheme.titleFont(20))
      .foregroundStyle(StyleTheme.textSecondary)
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        let allIsActive = store.activeBoardFilter == nil
        Button("All") {
          store.activeBoardFilter = nil
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .font(StyleTheme.bodyFont(14, weight: allIsActive ? .semibold : .regular))
        .foregroundStyle(allIsActive ? StyleTheme.textPrimary : StyleTheme.textSecondary)
        .buttonStyle(.plain)

        ForEach(store.selectedBoards) { board in
          let boardIsActive = store.activeBoardFilter == board.id
          Button(board.name) {
            store.activeBoardFilter = board.id
          }
          .padding(.horizontal, 8)
          .padding(.vertical, 6)
          .font(StyleTheme.bodyFont(14, weight: boardIsActive ? .semibold : .regular))
          .foregroundStyle(boardIsActive ? StyleTheme.textPrimary : StyleTheme.textSecondary)
          .buttonStyle(.plain)
        }
      }
      .padding(.bottom, 2)
    }
  }

  @ViewBuilder
  private var homeTab: some View {
    boardFilterBar

    if store.homeProducts.isEmpty {
      Text("No new products for current filters.")
    }

    ForEach(store.homeProducts) { product in
      SwipeableCard(
        onTap: { store.selectedProduct = product },
        onSwipeLeft: { store.archiveFromHomeSwipe(product) },
        onSwipeRight: { store.likeFromHomeSwipe(product) }
      ) {
        homeProductCard(product)
      }
    }
  }

  @ViewBuilder
  private var moodboardsTab: some View {
    Text("Pinterest Moodboards")
      .font(StyleTheme.titleFont(24))
      .foregroundStyle(StyleTheme.textPrimary)
    Text("All selected moodboards with visual covers. Open one to see pins and bought items.")
      .font(StyleTheme.bodyFont(12))
      .foregroundStyle(StyleTheme.textTertiary)
    boardFilterBar

    if store.visibleBoardsForTabs.isEmpty {
      Text("No selected moodboards yet.")
    }

    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
      ForEach(store.visibleBoardsForTabs) { board in
        Button {
          store.selectedMoodboard = board
        } label: {
          VStack(alignment: .leading, spacing: 8) {
            WireframeImageBlock(height: 124, label: "Moodboard Cover")
            HStack(spacing: 8) {
              WireframeImageBlock(height: 124, label: "Pin")
                .frame(maxWidth: .infinity)
              WireframeImageBlock(height: 124, label: "Pin")
                .frame(maxWidth: .infinity)
            }

            Text(board.name).bold()
              .font(StyleTheme.bodyFont(15, weight: .semibold))
              .lineLimit(2)
              .foregroundStyle(StyleTheme.textPrimary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
          .background(Color.clear)
          .contentShape(Rectangle())
          .frame(minHeight: 300)
          .punkTexture(0.3)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func homeProductCard(_ product: Product) -> some View {
    GeometryReader { proxy in
      let cardHeight: CGFloat = 170
      let infoWidth = max(126, proxy.size.width * 0.3)
      let visualWidth = max(170, proxy.size.width - infoWidth - 18)
      let bigImageWidth = max(102, visualWidth * 0.62)
      let stackedWidth = max(58, visualWidth - bigImageWidth - 8)
      let smallImageHeight = (cardHeight - 8) / 2

      HStack(spacing: 10) {
        HStack(spacing: 8) {
          WireframeImageBlock(width: bigImageWidth, height: cardHeight, label: "Main")
          VStack(spacing: 8) {
            WireframeImageBlock(width: stackedWidth, height: smallImageHeight, label: "Alt")
            WireframeImageBlock(width: stackedWidth, height: smallImageHeight, label: "Alt")
          }
        }
        .frame(width: visualWidth, alignment: .leading)

        VStack(alignment: .leading, spacing: 4) {
          Text(store.likedProductIDs.contains(product.id) ? "LIKED" : "NEW")
            .font(StyleTheme.titleFont(13))
            .foregroundStyle(store.likedProductIDs.contains(product.id) ? StyleTheme.accentBright : StyleTheme.badgeNeutral)
          HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(product.title)
              .font(StyleTheme.titleFont(20))
              .lineLimit(2)
              .foregroundStyle(StyleTheme.textPrimary)
            Spacer(minLength: 4)
            Text("CHF \(product.priceCHF)")
              .font(StyleTheme.bodyFont(14, weight: .semibold))
              .foregroundStyle(StyleTheme.textPrimary)
          }
          Text(product.brand)
            .font(StyleTheme.bodyFont(12))
            .foregroundStyle(StyleTheme.textSecondary)
          Text(product.designer)
            .font(StyleTheme.bodyFont(12))
            .foregroundStyle(StyleTheme.textSecondary)
          Text("Score \(store.score(for: product))")
            .font(StyleTheme.bodyFont(11))
            .foregroundStyle(StyleTheme.textTertiary)
        }
        .frame(width: infoWidth, alignment: .leading)
      }
      .frame(height: cardHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background(Color.clear)
      .punkTexture(0.3)
    }
    .frame(height: 186)
  }

  @ViewBuilder
  private var archiveTab: some View {
    boardFilterBar

    if store.archivedProductsForCurrentFilter.isEmpty {
      Text("No archived products for current filter.")
    }

    ForEach(store.archivedProductsForCurrentFilter) { product in
      archiveProductCard(product)
        .onTapGesture {
          store.selectedProduct = product
        }
    }
  }

  private func archiveProductCard(_ product: Product) -> some View {
    GeometryReader { proxy in
      let cardHeight: CGFloat = 152
      let imageWidth = max(160, proxy.size.width * 0.66)
      let textWidth = max(100, proxy.size.width - imageWidth - 12)

      HStack(spacing: 10) {
        WireframeImageBlock(width: imageWidth, height: cardHeight, label: "Archived")

        VStack(alignment: .leading, spacing: 6) {
          Text(product.title)
            .font(StyleTheme.titleFont(18))
            .lineLimit(2)
            .foregroundStyle(StyleTheme.textPrimary)
          Text("CHF \(product.priceCHF)")
            .font(StyleTheme.bodyFont(14, weight: .semibold))
            .foregroundStyle(StyleTheme.textPrimary)
          Text(store.boardName(for: product.boardID))
            .font(StyleTheme.bodyFont(12))
            .foregroundStyle(StyleTheme.textSecondary)
        }
        .frame(width: textWidth, alignment: .leading)
      }
      .frame(height: cardHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background(Color.clear)
      .punkTexture(0.3)
    }
    .frame(height: 170)
  }

}

struct ProductDetailSheetView: View {
  @ObservedObject var store: PrototypeStore
  let product: Product
  @State private var currentImageIndex = 0

  private var galleryLabels: [String] {
    ["Product 1", "Product 2", "Product 3", "Product 4"]
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          TabView(selection: $currentImageIndex) {
            ForEach(Array(galleryLabels.enumerated()), id: \.offset) { index, label in
              WireframeImageBlock(height: 290, label: label)
                .padding(.horizontal, 2)
                .tag(index)
            }
          }
          .frame(height: 300)
          .tabViewStyle(.page(indexDisplayMode: .automatic))

          Text(product.title)
            .font(StyleTheme.titleFont(30))
            .foregroundStyle(StyleTheme.textPrimary)

          Text("Curated from your moodboard style. This product is ranked higher because fit, shape and overall vibe align with your current board direction.")
            .font(StyleTheme.bodyFont(16))
            .foregroundStyle(StyleTheme.textSecondary)

          VStack(spacing: 0) {
            Divider()
              .overlay(StyleTheme.border)
            infoRow(title: "Price", value: "CHF \(product.priceCHF)")
            Divider()
              .overlay(StyleTheme.border)
            infoRow(title: "Brand", value: product.brand)
            Divider()
              .overlay(StyleTheme.border)
            infoRow(title: "Designer", value: product.designer)
            Divider()
              .overlay(StyleTheme.border)
            infoRow(title: "Shop", value: product.shop)
            Divider()
              .overlay(StyleTheme.border)
            infoRow(title: "Moodboard", value: store.boardName(for: product.boardID))
            Divider()
              .overlay(StyleTheme.border)
          }

          Text("Buy now")
            .font(StyleTheme.titleFont(28))
            .foregroundStyle(StyleTheme.textPrimary)

          Button("Buy now") {
            // Placeholder: in MVP this opens the product in store with selected size.
          }
          .font(StyleTheme.titleFont(22))
          .foregroundStyle(StyleTheme.textPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.vertical, 6)

          HStack(spacing: 24) {
            iconAction(
              symbol: store.likedProductIDs.contains(product.id) ? "hand.thumbsup.fill" : "hand.thumbsup",
              label: "Like",
              isActive: store.likedProductIDs.contains(product.id)
            ) {
              store.toggleLike(product)
            }
            iconAction(
              symbol: store.dislikedProductIDs.contains(product.id) ? "hand.thumbsdown.fill" : "hand.thumbsdown",
              label: "Dislike",
              isActive: store.dislikedProductIDs.contains(product.id)
            ) {
              store.toggleDislike(product)
            }
            iconAction(
              symbol: store.archivedProductIDs.contains(product.id) ? "archivebox.fill" : "archivebox",
              label: "Archive",
              isActive: store.archivedProductIDs.contains(product.id)
            ) {
              store.toggleArchive(product)
            }
            iconAction(
              symbol: store.boughtProductIDs.contains(product.id) ? "bag.fill" : "bag",
              label: "Bought",
              isActive: store.boughtProductIDs.contains(product.id)
            ) {
              store.toggleBought(product)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
      }
      .navigationTitle("Product")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { store.selectedProduct = nil }
            .font(StyleTheme.titleFont(16))
        }
      }
    }
  }

  private func infoRow(title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(StyleTheme.bodyFont(14))
        .foregroundStyle(StyleTheme.textSecondary)
      Spacer()
      Text(value)
        .font(StyleTheme.bodyFont(14, weight: .semibold))
        .foregroundStyle(StyleTheme.textPrimary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }

  private func iconAction(symbol: String, label: String, isActive: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol)
          .font(.system(size: 20, weight: isActive ? .bold : .regular))
        Text(label)
          .font(StyleTheme.bodyFont(11, weight: isActive ? .semibold : .regular))
      }
      .foregroundStyle(isActive ? StyleTheme.textPrimary : StyleTheme.textSecondary)
    }
    .buttonStyle(.plain)
  }
}

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let root = PrototypeRootView()
    let hosting = UIHostingController(rootView: root)

    let window = UIWindow(frame: UIScreen.main.bounds)
    window.rootViewController = hosting
    window.makeKeyAndVisible()
    self.window = window

    return true
  }
}

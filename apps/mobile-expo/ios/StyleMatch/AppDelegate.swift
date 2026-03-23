import UIKit
import SwiftUI

enum StyleTheme {
  // Palette sampled from app icon: near-black base + muted deep maroon accents.
  static let bg = Color(red: 0.050, green: 0.050, blue: 0.050)
  static let surface = Color(red: 0.080, green: 0.078, blue: 0.078)
  static let surfaceAlt = Color(red: 0.110, green: 0.105, blue: 0.105)
  static let border = Color(red: 0.205, green: 0.190, blue: 0.190)
  static let textPrimary = Color(red: 0.935, green: 0.930, blue: 0.925)
  static let textSecondary = Color(red: 0.690, green: 0.680, blue: 0.680)
  static let accent = Color(red: 0.220, green: 0.094, blue: 0.125)
  static let accentBright = Color(red: 0.320, green: 0.125, blue: 0.157)
  static let badgeNeutral = Color(red: 0.830, green: 0.830, blue: 0.840)
  static let blackCTA = Color(red: 0.020, green: 0.020, blue: 0.020)
}

struct NoiseOverlay: View {
  var body: some View {
    GeometryReader { _ in
      Canvas { context, size in
        let w = max(1, Int(size.width))
        let h = max(1, Int(size.height))

        let brightDots = max(900, Int(size.width * size.height / 760))
        for i in 0..<brightDots {
          let x = CGFloat((i * 73 + 17) % w)
          let y = CGFloat((i * 97 + 29) % h)
          let alpha = 0.012 + Double((i * 31) % 19) / 150.0
          let rect = CGRect(x: x, y: y, width: 1.2, height: 1.2)
          context.fill(Path(rect), with: .color(.white.opacity(alpha)))
        }

        let darkDots = max(700, Int(size.width * size.height / 980))
        for i in 0..<darkDots {
          let x = CGFloat((i * 83 + 41) % w)
          let y = CGFloat((i * 59 + 13) % h)
          let alpha = 0.010 + Double((i * 23) % 17) / 170.0
          let rect = CGRect(x: x, y: y, width: 1.1, height: 1.1)
          context.fill(Path(rect), with: .color(.black.opacity(alpha)))
        }
      }
      .blendMode(.overlay)
      .opacity(0.52)
    }
    .allowsHitTesting(false)
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

enum MainTab {
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
  let cornerRadius: CGFloat
  var label: String = "Image"

  init(width: CGFloat? = nil, height: CGFloat, cornerRadius: CGFloat = 10, label: String = "Image") {
    self.width = width
    self.height = height
    self.cornerRadius = cornerRadius
    self.label = label
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(StyleTheme.surfaceAlt)

      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(StyleTheme.border, lineWidth: 1)

      VStack(spacing: 4) {
        Image(systemName: "photo")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(StyleTheme.textSecondary)
        Text(label)
          .font(.caption2)
          .foregroundStyle(StyleTheme.textSecondary)
      }
    }
    .frame(width: width, height: height)
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
      RoundedRectangle(cornerRadius: 12)
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
    .clipShape(RoundedRectangle(cornerRadius: 12))
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
  @Published var hasAcceptedCompliance: Bool = false

  let availableDesigners: [String]
  let availableBrands: [String]
  let availableQualities: [String]
  let availableCountries: [String]
  let allBoards: [Moodboard]
  let allProducts: [Product]

  init() {
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
    hasAcceptedCompliance = false
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
    }
  }

  func archiveFromHomeSwipe(_ product: Product) {
    archivedProductIDs.insert(product.id)
    likedProductIDs.remove(product.id)
  }

  func likeFromHomeSwipe(_ product: Product) {
    likedProductIDs.insert(product.id)
    archivedProductIDs.remove(product.id)
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
          .font(.title3)
          .bold()
          .foregroundStyle(StyleTheme.textPrimary)

        Text("Set filters for this moodboard only.")
          .font(.caption)
          .foregroundStyle(StyleTheme.textSecondary)

        Text("Brand").font(.headline)
        HStack {
          TextField("Add brand", text: $customBrandName)
            .textFieldStyle(.roundedBorder)
          Button("Add") {
            store.addCustomBrand(for: board.id, name: customBrandName)
            customBrandName = ""
          }
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

        Text("Designer").font(.headline)
        HStack {
          TextField("Add designer", text: $customDesignerName)
            .textFieldStyle(.roundedBorder)
          Button("Add") {
            store.addCustomDesigner(for: board.id, name: customDesignerName)
            customDesignerName = ""
          }
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

        Text("Price").font(.headline)
        Text("CHF \(Int(store.priceMin(for: board.id))) - \(Int(store.priceMax(for: board.id)))")
          .font(.subheadline)
          .bold()
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

        Text("Quality").font(.headline)
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

        Text("Country of origin").font(.headline)
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
    .background(StyleTheme.bg)
  }

  private func settingsChip(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      HStack {
        Text(title)
          .lineLimit(1)
        Spacer()
        Image(systemName: selected ? "checkmark.circle.fill" : "circle")
      }
      .padding(10)
      .background(selected ? StyleTheme.accent : StyleTheme.surfaceAlt)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .foregroundStyle(StyleTheme.textPrimary)
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
            .font(.headline)
            .foregroundStyle(StyleTheme.textPrimary)
          categoryTabs
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(StyleTheme.surface)

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
          .font(.subheadline)
          .bold()
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
          .font(.headline)
          .foregroundStyle(StyleTheme.textPrimary)
        Text("Swipe left for purchases, swipe left again for settings.")
          .font(.caption)
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
          .font(.headline)
          .foregroundStyle(StyleTheme.textPrimary)
        let bought = store.boughtProducts(for: board)
        if bought.isEmpty {
          Text("No purchases for this moodboard yet.")
            .foregroundStyle(StyleTheme.textSecondary)
            .padding(.top, 8)
        } else {
          ForEach(bought) { product in
            HStack(spacing: 10) {
              WireframeImageBlock(width: 70, height: 70, cornerRadius: 8, label: "Product")

              VStack(alignment: .leading, spacing: 3) {
                Text(product.title).bold()
                  .foregroundStyle(StyleTheme.textPrimary)
                Text("CHF \(product.priceCHF)")
                  .foregroundStyle(StyleTheme.textPrimary)
                Text("\(product.brand) · \(product.designer)")
                  .font(.caption)
                  .foregroundStyle(StyleTheme.textSecondary)
              }
              Spacer()
            }
            .padding(10)
            .background(StyleTheme.surfaceAlt)
            .clipShape(RoundedRectangle(cornerRadius: 10))
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
    WireframeImageBlock(height: height, cornerRadius: 12, label: "Pin")
      .frame(maxWidth: .infinity)
  }
}

struct PrototypeRootView: View {
  @StateObject private var store = PrototypeStore()

  var body: some View {
    NavigationStack {
      ZStack {
        StyleTheme.bg.ignoresSafeArea()
        NoiseOverlay().ignoresSafeArea()

        Group {
          if store.setupStep != .done {
            ScrollView {
              VStack(alignment: .leading, spacing: 14) {
                setupFlow
              }
              .padding(16)
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
    .preferredColorScheme(.dark)
  }

  @ViewBuilder
  private var setupFlow: some View {
    switch store.setupStep {
    case .intro1, .intro2, .intro3:
      setupHeroSection(
        title: store.introTitle(),
        imageLabel: "Intro",
        description: store.introText()
      )
      Button(store.setupStep == .intro3 ? "Continue to Login" : "Next") {
        store.nextIntroStep()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(StyleTheme.blackCTA)
      .foregroundStyle(StyleTheme.textPrimary)
      .clipShape(RoundedRectangle(cornerRadius: 12))

    case .login:
      setupHeroSection(
        title: "Pinterest Login",
        imageLabel: "Login",
        description: "Connect your Pinterest account to load your liked pins and selected moodboards."
      )
      Button("Connect Pinterest") {
        store.connectPinterest()
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 14)
      .background(StyleTheme.blackCTA)
      .foregroundStyle(StyleTheme.textPrimary)
      .clipShape(RoundedRectangle(cornerRadius: 12))

    case .boards:
      Text("Select moodboard")
        .font(.custom("Times New Roman", size: 42))
        .lineSpacing(8.4)
        .tracking(0.6)
        .foregroundStyle(StyleTheme.textPrimary)
      TextField("Search board name", text: $store.boardSearch)
        .textFieldStyle(.roundedBorder)

      LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
        ForEach(store.filteredBoards) { board in
          let isSelected = store.selectedBoardIDs.contains(board.id)
          Button {
            store.toggleBoard(board)
          } label: {
            VStack(alignment: .leading, spacing: 8) {
              ZStack(alignment: .topTrailing) {
                WireframeImageBlock(height: 162, cornerRadius: 12, label: "Moodboard")
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundStyle(isSelected ? StyleTheme.accentBright : StyleTheme.textSecondary)
                  .padding(8)
              }

              Text(board.name)
                .font(.subheadline)
                .bold()
                .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(StyleTheme.surface)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? StyleTheme.accent : StyleTheme.border, lineWidth: 2)
            )
          }
          .buttonStyle(.plain)
        }
      }

      Text("Selected: \(store.selectedBoardIDs.count)")
        .foregroundStyle(StyleTheme.textSecondary)
      Button("Tap to get started") {
        store.continueFromBoards()
      }
      .disabled(store.selectedBoardIDs.isEmpty)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(StyleTheme.blackCTA)
      .foregroundStyle(StyleTheme.textPrimary)
      .clipShape(RoundedRectangle(cornerRadius: 12))

    case .done:
      EmptyView()
    }
  }

  private func setupHeroSection(title: String, imageLabel: String, description: String) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.custom("Times New Roman", size: 42))
        .lineSpacing(8.4)
        .tracking(0.6)
        .foregroundStyle(StyleTheme.textPrimary)
      WireframeImageBlock(height: 190, cornerRadius: 14, label: imageLabel)
      Text(description)
        .font(.body)
        .foregroundStyle(StyleTheme.textSecondary)
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
          .padding(.top, 8)
          .padding(.bottom, 16)
        } header: {
          stickyTabHeader
        }
      }
    }
  }

  private var stickyTabHeader: some View {
    HStack(spacing: 8) {
      tabHeaderButton(title: "Home", isActive: store.mainTab == .home) {
        store.mainTab = .home
      }
      tabHeaderButton(title: "Moodboards", isActive: store.mainTab == .moodboards) {
        store.mainTab = .moodboards
      }
      tabHeaderButton(title: "Archive", isActive: store.mainTab == .archive) {
        store.mainTab = .archive
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(StyleTheme.surface)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(StyleTheme.border)
        .frame(height: 1)
    }
  }

  private func tabHeaderButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Text(title)
        .font(.title2)
        .bold()
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isActive ? StyleTheme.accent : StyleTheme.surfaceAlt)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .foregroundStyle(StyleTheme.textPrimary)
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private var boardFilterBar: some View {
    Text("Moodboard Filter")
      .font(.system(.headline, design: .default))
      .foregroundStyle(StyleTheme.textPrimary)
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        Button(store.activeBoardFilter == nil ? "[All]" : "All") {
          store.activeBoardFilter = nil
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(store.activeBoardFilter == nil ? StyleTheme.accent : StyleTheme.surfaceAlt)
        .clipShape(Capsule())
        .foregroundStyle(StyleTheme.textPrimary)

        ForEach(store.selectedBoards) { board in
          Button(store.activeBoardFilter == board.id ? "[\(board.name)]" : board.name) {
            store.activeBoardFilter = board.id
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(store.activeBoardFilter == board.id ? StyleTheme.accent : StyleTheme.surfaceAlt)
          .clipShape(Capsule())
          .foregroundStyle(StyleTheme.textPrimary)
        }
      }
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
      .font(.system(.headline, design: .default))
      .foregroundStyle(StyleTheme.textPrimary)
    Text("All selected moodboards with visual covers. Open one to see pins and bought items.")
      .font(.caption)
      .foregroundStyle(StyleTheme.textSecondary)
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
            WireframeImageBlock(height: 124, cornerRadius: 12, label: "Moodboard Cover")
            HStack(spacing: 8) {
              WireframeImageBlock(height: 124, cornerRadius: 10, label: "Pin")
                .frame(maxWidth: .infinity)
              WireframeImageBlock(height: 124, cornerRadius: 10, label: "Pin")
                .frame(maxWidth: .infinity)
            }

            Text(board.name).bold()
              .lineLimit(2)
              .foregroundStyle(StyleTheme.textPrimary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
          .background(StyleTheme.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(StyleTheme.border, lineWidth: 1)
          )
          .contentShape(Rectangle())
          .frame(minHeight: 300)
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
          WireframeImageBlock(width: bigImageWidth, height: cardHeight, cornerRadius: 10, label: "Main")
          VStack(spacing: 8) {
            WireframeImageBlock(width: stackedWidth, height: smallImageHeight, cornerRadius: 10, label: "Alt")
            WireframeImageBlock(width: stackedWidth, height: smallImageHeight, cornerRadius: 10, label: "Alt")
          }
        }
        .frame(width: visualWidth, alignment: .leading)

        VStack(alignment: .leading, spacing: 4) {
          Text(store.likedProductIDs.contains(product.id) ? "LIKED" : "NEW")
            .font(.caption)
            .bold()
            .foregroundStyle(store.likedProductIDs.contains(product.id) ? StyleTheme.accentBright : StyleTheme.badgeNeutral)
          Text(product.title)
            .bold()
            .lineLimit(2)
            .foregroundStyle(StyleTheme.textPrimary)
          Text("CHF \(product.priceCHF)")
            .font(.subheadline)
            .foregroundStyle(StyleTheme.textPrimary)
          Text(product.brand)
            .font(.caption)
            .foregroundStyle(StyleTheme.textSecondary)
          Text(product.designer)
            .font(.caption)
            .foregroundStyle(StyleTheme.textSecondary)
          Text("Score \(store.score(for: product))")
            .font(.caption2)
            .foregroundStyle(StyleTheme.textSecondary)
        }
        .frame(width: infoWidth, alignment: .leading)
      }
      .frame(height: cardHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background(StyleTheme.surface)
      .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(StyleTheme.border, lineWidth: 1)
      )
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
        WireframeImageBlock(width: imageWidth, height: cardHeight, cornerRadius: 10, label: "Archived")

        VStack(alignment: .leading, spacing: 6) {
          Text(product.title)
            .font(.subheadline)
            .bold()
            .lineLimit(2)
            .foregroundStyle(StyleTheme.textPrimary)
          Text("CHF \(product.priceCHF)")
            .font(.subheadline)
            .foregroundStyle(StyleTheme.textPrimary)
          Text(store.boardName(for: product.boardID))
            .font(.caption)
            .foregroundStyle(StyleTheme.textSecondary)
        }
        .frame(width: textWidth, alignment: .leading)
      }
      .frame(height: cardHeight)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background(StyleTheme.surface)
      .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(StyleTheme.border, lineWidth: 1)
      )
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
              WireframeImageBlock(height: 290, cornerRadius: 14, label: label)
                .padding(.horizontal, 2)
                .tag(index)
            }
          }
          .frame(height: 300)
          .tabViewStyle(.page(indexDisplayMode: .automatic))

          Text(product.title)
            .font(.title3)
            .bold()
            .foregroundStyle(StyleTheme.textPrimary)

          Text("Curated from your moodboard style. This product is ranked higher because fit, shape and overall vibe align with your current board direction.")
            .font(.body)
            .foregroundStyle(StyleTheme.textSecondary)

          VStack(spacing: 0) {
            infoRow(title: "Price", value: "CHF \(product.priceCHF)")
            Divider()
            infoRow(title: "Brand", value: product.brand)
            Divider()
            infoRow(title: "Designer", value: product.designer)
            Divider()
            infoRow(title: "Shop", value: product.shop)
            Divider()
            infoRow(title: "Moodboard", value: store.boardName(for: product.boardID))
          }
          .background(StyleTheme.surfaceAlt)
          .clipShape(RoundedRectangle(cornerRadius: 12))

          Text("Buy now")
            .font(.title2)
            .bold()
            .foregroundStyle(StyleTheme.textPrimary)

          Button("Buy now") {
            // Placeholder: in MVP this opens the product in store with selected size.
          }
          .font(.headline)
          .foregroundStyle(StyleTheme.textPrimary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 14)
          .background(StyleTheme.blackCTA)
          .clipShape(RoundedRectangle(cornerRadius: 12))

          HStack(spacing: 24) {
            iconAction(symbol: "hand.thumbsup", label: "Like") {}
            iconAction(symbol: "hand.thumbsdown", label: "Dislike") {}
            iconAction(
              symbol: store.archivedProductIDs.contains(product.id) ? "archivebox.fill" : "archivebox",
              label: "Archive"
            ) {
              store.toggleArchive(product)
            }
            iconAction(
              symbol: store.boughtProductIDs.contains(product.id) ? "bag.fill" : "bag",
              label: "Bought"
            ) {
              store.toggleBought(product)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
      }
      .navigationTitle("Product")
      .toolbarBackground(StyleTheme.surface, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { store.selectedProduct = nil }
        }
      }
    }
  }

  private func infoRow(title: String, value: String) -> some View {
    HStack(alignment: .firstTextBaseline) {
      Text(title)
        .font(.subheadline)
        .foregroundStyle(StyleTheme.textSecondary)
      Spacer()
      Text(value)
        .font(.subheadline)
        .bold()
        .foregroundStyle(StyleTheme.textPrimary)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
  }

  private func iconAction(symbol: String, label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 6) {
        Image(systemName: symbol)
          .font(.system(size: 20, weight: .semibold))
        Text(label)
          .font(.caption2)
      }
      .foregroundStyle(StyleTheme.textPrimary)
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

import UIKit
import SwiftUI

enum SetupStep {
  case intro1
  case intro2
  case intro3
  case login
  case boards
  case preferences
  case analyzing
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

final class PrototypeStore: ObservableObject {
  @Published var setupStep: SetupStep = .done
  @Published var mainTab: MainTab = .home

  @Published var boardSearch: String = ""
  @Published var selectedBoardIDs: Set<UUID> = []

  @Published var sizeProfile: String = "M"
  @Published var selectedBrandFocus: Set<String> = []
  @Published var priceMin: Double = 200
  @Published var priceMax: Double = 2000

  @Published var moodboardDesignerFocus: [UUID: Set<String>] = [:]
  @Published var customDesignersByBoard: [UUID: [String]] = [:]

  @Published var activeBoardFilter: UUID? = nil
  @Published var selectedProduct: Product? = nil
  @Published var selectedMoodboard: Moodboard? = nil

  @Published var archivedProductIDs: Set<UUID> = []
  @Published var boughtProductIDs: Set<UUID> = []

  let availableDesigners: [String]
  let availableBrands: [String]
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
      setupStep = .preferences
    }
  }

  func startAnalysis() {
    setupStep = .analyzing
  }

  func finishAnalysis() {
    setupStep = .done
    mainTab = .home
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
    activeBoardFilter = nil
    selectedProduct = nil
    selectedMoodboard = nil
    archivedProductIDs = []
    boughtProductIDs = []
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

  func toggleBought(_ product: Product) {
    if boughtProductIDs.contains(product.id) {
      boughtProductIDs.remove(product.id)
    } else {
      boughtProductIDs.insert(product.id)
    }
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
}

struct BoardSettingsView: View {
  @ObservedObject var store: PrototypeStore
  let board: Moodboard
  @State private var customDesignerName = ""

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Text("Moodboard Settings")
          .font(.title3)
          .bold()

        Text("Designer focus is moodboard specific and boosts ranking only.")
          .font(.caption)
          .foregroundStyle(.secondary)

        HStack {
          TextField("Add designer", text: $customDesignerName)
            .textFieldStyle(.roundedBorder)
          Button("Add") {
            store.addCustomDesigner(for: board.id, name: customDesignerName)
            customDesignerName = ""
          }
        }

        Text("Designer focus").font(.headline)
        ForEach(store.designersForBoard(board), id: \.self) { designer in
          Button {
            store.toggleDesignerFocus(for: board.id, designer: designer)
          } label: {
            HStack {
              Image(systemName: store.designerFocus(for: board.id).contains(designer) ? "checkmark.circle.fill" : "circle")
              Text(designer)
              Spacer()
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(16)
    }
  }
}

struct BoardDetailView: View {
  @ObservedObject var store: PrototypeStore
  let board: Moodboard
  @State private var pageSelection = 2

  var body: some View {
    NavigationStack {
      TabView(selection: $pageSelection) {
        BoardSettingsView(store: store, board: board)
          .tag(0)

        purchasesPage
          .tag(1)

        pinsPage
          .tag(2)
      }
      .tabViewStyle(.page(indexDisplayMode: .never))
      .navigationTitle(board.name)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Text(pageTitle(for: pageSelection))
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
      }
      .onAppear {
        pageSelection = 2
      }
    }
  }

  private var pinsPage: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 12) {
        Text("Pinterest-like pins")
          .font(.headline)
        Text("Swipe right for purchases, swipe right again for settings.")
          .font(.caption)
          .foregroundStyle(.secondary)

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
        let bought = store.boughtProducts(for: board)
        if bought.isEmpty {
          Text("No purchases for this moodboard yet.")
            .foregroundStyle(.secondary)
            .padding(.top, 8)
        } else {
          ForEach(bought) { product in
            HStack(spacing: 10) {
              AsyncImage(url: URL(string: product.productImageURL)) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipped()
                    .cornerRadius(8)
                default:
                  RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 70, height: 70)
                }
              }

              VStack(alignment: .leading, spacing: 3) {
                Text(product.title).bold()
                Text("CHF \(product.priceCHF)")
                Text("\(product.brand) · \(product.designer)")
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
            }
            .padding(10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
          }
        }
      }
      .padding(16)
    }
  }

  private func pageTitle(for page: Int) -> String {
    switch page {
    case 0:
      return "Settings"
    case 1:
      return "Purchases"
    default:
      return "Pins"
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
    AsyncImage(url: URL(string: url)) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity)
          .frame(height: height)
          .clipped()
          .cornerRadius(12)
      default:
        RoundedRectangle(cornerRadius: 12)
          .fill(.gray.opacity(0.2))
          .frame(height: height)
      }
    }
  }
}

struct PrototypeRootView: View {
  @StateObject private var store = PrototypeStore()

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          if store.setupStep != .done {
            setupFlow
          } else {
            appFlow
          }
        }
        .padding(16)
      }
      .navigationTitle("StyleMatch Prototype")
      .sheet(item: $store.selectedProduct) { product in
        productDetailSheet(product)
      }
      .sheet(item: $store.selectedMoodboard) { board in
        BoardDetailView(store: store, board: board)
      }
    }
  }

  @ViewBuilder
  private var setupFlow: some View {
    switch store.setupStep {
    case .intro1, .intro2, .intro3:
      Text(store.introTitle()).font(.title2).bold()
      Text(store.introText())
      Button(store.setupStep == .intro3 ? "Continue to Login" : "Next") {
        store.nextIntroStep()
      }

    case .login:
      Text("Pinterest Login").font(.title2).bold()
      Text("Prototype step: connect your Pinterest account.")
      Button("Connect Pinterest") {
        store.connectPinterest()
      }

    case .boards:
      Text("Select Pinterest Moodboards (1-10)").font(.title2).bold()
      TextField("Search board name", text: $store.boardSearch)
        .textFieldStyle(.roundedBorder)

      ForEach(store.filteredBoards) { board in
        Button {
          store.toggleBoard(board)
        } label: {
          HStack(spacing: 10) {
            AsyncImage(url: URL(string: board.coverImageURL)) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 56, height: 56)
                  .clipped()
                  .cornerRadius(8)
              default:
                RoundedRectangle(cornerRadius: 8)
                  .fill(.gray.opacity(0.2))
                  .frame(width: 56, height: 56)
              }
            }

            VStack(alignment: .leading) {
              Text(board.name)
              Text(store.selectedBoardIDs.contains(board.id) ? "selected" : "tap to select")
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
            Text(store.selectedBoardIDs.contains(board.id) ? "[x]" : "[ ]")
          }
        }
        .buttonStyle(.plain)
      }

      Text("Selected: \(store.selectedBoardIDs.count)")
      Button("Continue") {
        store.continueFromBoards()
      }
      .disabled(store.selectedBoardIDs.isEmpty)

    case .preferences:
      Text("Preferences").font(.title2).bold()
      Text("Brands are used as focus (boost), not as strict exclusion.")
      Text("Designer focus is set later per moodboard in moodboard settings.")

      TextField("Size profile", text: $store.sizeProfile)
        .textFieldStyle(.roundedBorder)

      Text("Brand focus (multi-select)").bold()
      ForEach(store.availableBrands, id: \.self) { brand in
        Button {
          store.toggleBrandFocus(brand)
        } label: {
          HStack {
            Text(store.selectedBrandFocus.contains(brand) ? "[x]" : "[ ]")
            Text(brand)
            Spacer()
          }
        }
      }

      Text("Price range: CHF \(Int(store.priceMin)) - \(Int(store.priceMax))").bold()
      Text("From")
      Slider(
        value: Binding(
          get: { store.priceMin },
          set: { store.priceMin = min($0, store.priceMax) }
        ),
        in: 0...5000,
        step: 10
      )

      Text("To")
      Slider(
        value: Binding(
          get: { store.priceMax },
          set: { store.priceMax = max($0, store.priceMin) }
        ),
        in: 0...5000,
        step: 10
      )

      HStack {
        Button("Preset 200-2000") {
          store.priceMin = 200
          store.priceMax = 2000
        }

        Button("Start Analysis") {
          store.startAnalysis()
        }
      }

    case .analyzing:
      Text("Analyzing Moodboards").font(.title2).bold()
      Text("Prototype step: pins are analyzed and first products are found.")
      Button("Open App") {
        store.finishAnalysis()
      }

    case .done:
      EmptyView()
    }
  }

  @ViewBuilder
  private var appFlow: some View {
    Text("StyleMatch").font(.title2).bold()

    HStack {
      Button(store.mainTab == .home ? "[Home]" : "Home") { store.mainTab = .home }
      Button(store.mainTab == .moodboards ? "[Moodboards]" : "Moodboards") { store.mainTab = .moodboards }
      Button(store.mainTab == .archive ? "[Archive]" : "Archive") { store.mainTab = .archive }
    }

    switch store.mainTab {
    case .home:
      homeTab
    case .moodboards:
      moodboardsTab
    case .archive:
      archiveTab
    }
  }

  @ViewBuilder
  private var boardFilterBar: some View {
    Text("Moodboard Filter").font(.headline)
    ScrollView(.horizontal) {
      HStack(spacing: 8) {
        Button(store.activeBoardFilter == nil ? "[All]" : "All") {
          store.activeBoardFilter = nil
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(store.activeBoardFilter == nil ? Color.red.opacity(0.16) : Color(.systemGray6))
        .clipShape(Capsule())

        ForEach(store.selectedBoards) { board in
          Button(store.activeBoardFilter == board.id ? "[\(board.name)]" : board.name) {
            store.activeBoardFilter = board.id
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 10)
          .background(store.activeBoardFilter == board.id ? Color.red.opacity(0.16) : Color(.systemGray6))
          .clipShape(Capsule())
        }
      }
    }
  }

  @ViewBuilder
  private var homeTab: some View {
    Text("Home: all new offers").font(.headline)
    Text("Brand focus: boosts ranking, does not exclude other products.")
      .font(.caption)
      .foregroundStyle(.secondary)

    ScrollView(.horizontal) {
      HStack {
        ForEach(store.availableBrands, id: \.self) { brand in
          Button(store.selectedBrandFocus.contains(brand) ? "[\(brand)]" : brand) {
            store.toggleBrandFocus(brand)
          }
        }
      }
    }

    boardFilterBar

    if store.homeProducts.isEmpty {
      Text("No new products for current filters.")
    }

    ForEach(store.homeProducts) { product in
      Button {
        store.selectedProduct = product
      } label: {
        homeProductCard(product)
      }
      .buttonStyle(.plain)
    }
  }

  @ViewBuilder
  private var moodboardsTab: some View {
    Text("Pinterest Moodboards").font(.headline)
    Text("All selected moodboards with visual covers. Open one to see pins and bought items.")
      .font(.caption)
      .foregroundStyle(.secondary)

    if store.moodboardsOverviewBoards.isEmpty {
      Text("No selected moodboards yet.")
    }

    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
      ForEach(store.moodboardsOverviewBoards) { board in
        Button {
          store.selectedMoodboard = board
        } label: {
          VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: board.coverImageURL)) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .scaledToFill()
                  .frame(height: 170)
                  .clipped()
                  .cornerRadius(12)
              default:
                RoundedRectangle(cornerRadius: 12)
                  .fill(.gray.opacity(0.2))
                  .frame(height: 170)
              }
            }

            Text(board.name).bold()
              .lineLimit(2)
            Text("Bought: \(store.boughtProducts(for: board).count)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(8)
          .background(Color(.systemBackground))
          .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.3), lineWidth: 1)
          )
          .contentShape(Rectangle())
          .frame(minHeight: 250)
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func homeProductCard(_ product: Product) -> some View {
    GeometryReader { proxy in
      let infoWidth = max(125, proxy.size.width * 0.34)
      let imageWidth = max(140, proxy.size.width - infoWidth - 16)

      HStack(spacing: 10) {
        AsyncImage(url: URL(string: product.productImageURL)) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .scaledToFill()
              .frame(width: imageWidth, height: 138)
              .clipped()
              .cornerRadius(10)
          default:
            RoundedRectangle(cornerRadius: 10)
              .fill(.gray.opacity(0.2))
              .frame(width: imageWidth, height: 138)
          }
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("NEW")
            .font(.caption)
            .bold()
            .foregroundStyle(.red)
          Text(product.title)
            .bold()
            .lineLimit(2)
          Text("CHF \(product.priceCHF)")
            .font(.subheadline)
          Text(product.brand)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(product.designer)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text("Score \(store.score(for: product))")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(width: infoWidth, alignment: .leading)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(8)
      .background(Color(.systemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.35), lineWidth: 1)
      )
    }
    .frame(height: 154)
  }

  @ViewBuilder
  private var archiveTab: some View {
    Text("Archive").font(.headline)
    boardFilterBar

    if store.visibleBoardsForTabs.isEmpty {
      Text("No moodboards for current filter.")
    }

    ForEach(store.visibleBoardsForTabs) { board in
      VStack(alignment: .leading, spacing: 4) {
        Text(board.name).bold()
        let archived = store.archivedProducts(for: board)
        if archived.isEmpty {
          Text("No archived products.")
        } else {
          ForEach(archived) { product in
            Text("- \(product.title)")
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(10)
      .overlay(
        RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.4), lineWidth: 1)
      )
    }
  }

  private func productDetailSheet(_ product: Product) -> some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 12) {
        Text("Product Detail").font(.title3).bold()
        Text(product.title)
        Text("CHF \(product.priceCHF) · \(product.shop)")
        Text("Brand: \(product.brand)")
        Text("Designer: \(product.designer)")

        Button("Buy now") {
          // Placeholder: in MVP this opens the product in store with selected size.
        }

        HStack {
          Button("Like") {}
          Button("Dislike") {}
          Button(store.archivedProductIDs.contains(product.id) ? "Unarchive" : "Archive") {
            store.toggleArchive(product)
          }
          Button(store.boughtProductIDs.contains(product.id) ? "Unmark bought" : "Mark as bought") {
            store.toggleBought(product)
          }
        }

        Spacer()
      }
      .padding(16)
      .navigationTitle("Product")
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") { store.selectedProduct = nil }
        }
      }
    }
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

import { StatusBar } from "expo-status-bar";
import { useMemo, useState } from "react";
import {
  Alert,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View
} from "react-native";

type SetupScreen =
  | "intro-1"
  | "intro-2"
  | "intro-3"
  | "login"
  | "board-select"
  | "preferences"
  | "analyzing";

type AppTab = "home" | "moodboards" | "archive";
type AppScreen = "app" | "product-detail" | "settings";

type Board = {
  id: string;
  name: string;
};

type Product = {
  id: string;
  boardId: string;
  title: string;
  price: string;
  shop: string;
};

const BOARD_SUGGESTIONS: Board[] = [
  { id: "board_1", name: "Minimal Outfits" },
  { id: "board_2", name: "Streetwear Looks" },
  { id: "board_3", name: "Tailored Essentials" },
  { id: "board_4", name: "Neutral Winter Fits" },
  { id: "board_5", name: "Sneaker Rotation" }
];

const SAMPLE_PRODUCTS: Product[] = [
  { id: "prod_1", boardId: "board_1", title: "Wool Overshirt", price: "CHF 129", shop: "Arket" },
  { id: "prod_2", boardId: "board_2", title: "Relaxed Cargo Pant", price: "CHF 95", shop: "COS" },
  { id: "prod_3", boardId: "board_3", title: "Structured Blazer", price: "CHF 210", shop: "Massimo Dutti" },
  { id: "prod_4", boardId: "board_4", title: "Merino Turtleneck", price: "CHF 89", shop: "Uniqlo" },
  { id: "prod_5", boardId: "board_5", title: "Retro Sneaker", price: "CHF 140", shop: "Zalando" }
];

const INTRO_SLIDES = [
  "Find products that match your Pinterest style.",
  "Use board-based filters to control what gets found.",
  "Open the best matches and buy faster."
];

export default function App() {
  const [setupScreen, setSetupScreen] = useState<SetupScreen>("intro-1");
  const [appScreen, setAppScreen] = useState<AppScreen>("app");
  const [activeTab, setActiveTab] = useState<AppTab>("home");

  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [boardSearch, setBoardSearch] = useState("");
  const [selectedBoards, setSelectedBoards] = useState<Board[]>([]);
  const [sizeProfile, setSizeProfile] = useState("M");
  const [designerFilter, setDesignerFilter] = useState("");
  const [brandFilter, setBrandFilter] = useState("");
  const [priceFilter, setPriceFilter] = useState("200");
  const [countryFilter, setCountryFilter] = useState("");
  const [qualityFilter, setQualityFilter] = useState("");

  const [activeBoardFilter, setActiveBoardFilter] = useState<string | null>(null);
  const [selectedProduct, setSelectedProduct] = useState<Product | null>(null);
  const [archivedProductIds, setArchivedProductIds] = useState<Record<string, boolean>>({});

  const slideIndex =
    setupScreen === "intro-1" ? 0 : setupScreen === "intro-2" ? 1 : setupScreen === "intro-3" ? 2 : -1;

  const visibleBoards = useMemo(() => {
    const normalizedSearch = boardSearch.trim().toLowerCase();
    if (!normalizedSearch) return BOARD_SUGGESTIONS;
    return BOARD_SUGGESTIONS.filter((board) => board.name.toLowerCase().includes(normalizedSearch));
  }, [boardSearch]);

  const visibleProducts = useMemo(() => {
    if (!activeBoardFilter) return SAMPLE_PRODUCTS;
    return SAMPLE_PRODUCTS.filter((product) => product.boardId === activeBoardFilter);
  }, [activeBoardFilter]);

  const archivedProductsByBoard = useMemo(() => {
    const archivedProducts = SAMPLE_PRODUCTS.filter((product) => archivedProductIds[product.id]);
    return selectedBoards.map((board) => ({
      board,
      products: archivedProducts.filter((product) => product.boardId === board.id)
    }));
  }, [archivedProductIds, selectedBoards]);

  function toggleBoard(board: Board) {
    const exists = selectedBoards.some((item) => item.id === board.id);
    if (exists) {
      setSelectedBoards((prev) => prev.filter((item) => item.id !== board.id));
      if (activeBoardFilter === board.id) {
        setActiveBoardFilter(null);
      }
      return;
    }

    if (selectedBoards.length >= 10) {
      Alert.alert("Maximum reached", "You can select up to 10 moodboards.");
      return;
    }

    setSelectedBoards((prev) => [...prev, board]);
  }

  function completeBoardSelection() {
    if (selectedBoards.length < 1) {
      Alert.alert("Select at least one board", "Please choose 1 to 10 moodboards.");
      return;
    }
    setSetupScreen("preferences");
  }

  function finishPreferences() {
    setSetupScreen("analyzing");
  }

  function finishAnalyzing() {
    setActiveTab("home");
    setAppScreen("app");
    setSetupScreen("intro-1");
  }

  function completeLogin() {
    setIsLoggedIn(true);
    setSetupScreen("board-select");
  }

  function goToNextIntro() {
    if (setupScreen === "intro-1") setSetupScreen("intro-2");
    if (setupScreen === "intro-2") setSetupScreen("intro-3");
    if (setupScreen === "intro-3") setSetupScreen("login");
  }

  function resetToSetup() {
    setSetupScreen("intro-1");
    setAppScreen("app");
    setActiveTab("home");
    setIsLoggedIn(false);
    setSelectedBoards([]);
    setActiveBoardFilter(null);
    setArchivedProductIds({});
    setSelectedProduct(null);
  }

  function renderSetupFlow() {
    if (slideIndex >= 0) {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Intro {slideIndex + 1}/3</Text>
          <Text style={styles.text}>{INTRO_SLIDES[slideIndex]}</Text>
          <Pressable style={styles.button} onPress={goToNextIntro}>
            <Text style={styles.buttonText}>{slideIndex === 2 ? "Continue to Login" : "Next"}</Text>
          </Pressable>
        </View>
      );
    }

    if (setupScreen === "login") {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Pinterest Login</Text>
          <Text style={styles.text}>Step prototype: connect your Pinterest account.</Text>
          <Pressable style={styles.button} onPress={completeLogin}>
            <Text style={styles.buttonText}>Connect Pinterest</Text>
          </Pressable>
        </View>
      );
    }

    if (setupScreen === "board-select") {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Select Moodboards (1-10)</Text>
          <TextInput
            style={styles.input}
            placeholder="Search board name"
            value={boardSearch}
            onChangeText={setBoardSearch}
          />
          <ScrollView style={styles.list}>
            {visibleBoards.map((board) => {
              const selected = selectedBoards.some((item) => item.id === board.id);
              return (
                <Pressable key={board.id} style={styles.listItem} onPress={() => toggleBoard(board)}>
                  <Text>{selected ? "[x]" : "[ ]"} {board.name}</Text>
                </Pressable>
              );
            })}
          </ScrollView>
          <Text style={styles.text}>Selected: {selectedBoards.length}</Text>
          <Pressable style={styles.button} onPress={completeBoardSelection}>
            <Text style={styles.buttonText}>Continue</Text>
          </Pressable>
        </View>
      );
    }

    if (setupScreen === "preferences") {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Preferences</Text>
          <Text style={styles.text}>Colors and cuts are auto-detected from pins.</Text>

          <TextInput style={styles.input} value={sizeProfile} onChangeText={setSizeProfile} placeholder="Size profile" />
          <TextInput style={styles.input} value={designerFilter} onChangeText={setDesignerFilter} placeholder="Designer" />
          <TextInput style={styles.input} value={brandFilter} onChangeText={setBrandFilter} placeholder="Brands" />
          <TextInput style={styles.input} value={priceFilter} onChangeText={setPriceFilter} placeholder="Max price" keyboardType="number-pad" />
          <TextInput style={styles.input} value={countryFilter} onChangeText={setCountryFilter} placeholder="Country of origin" />
          <TextInput style={styles.input} value={qualityFilter} onChangeText={setQualityFilter} placeholder="Quality" />

          <View style={styles.row}>
            <Pressable style={styles.buttonSecondary} onPress={() => setSizeProfile("not-set") }>
              <Text>Skip size for now</Text>
            </Pressable>
            <Pressable style={styles.button} onPress={finishPreferences}>
              <Text style={styles.buttonText}>Start Analysis</Text>
            </Pressable>
          </View>
        </View>
      );
    }

    return (
      <View style={styles.block}>
        <Text style={styles.title}>Analyzing Moodboards</Text>
        <Text style={styles.text}>Prototype step: pins are analyzed and first products are found.</Text>
        <Pressable style={styles.button} onPress={finishAnalyzing}>
          <Text style={styles.buttonText}>Open App</Text>
        </Pressable>
      </View>
    );
  }

  function openProduct(product: Product) {
    setSelectedProduct(product);
    setAppScreen("product-detail");
  }

  function toggleArchive(productId: string) {
    setArchivedProductIds((prev) => ({ ...prev, [productId]: !prev[productId] }));
  }

  function renderHomeTab() {
    return (
      <View style={styles.block}>
        <Text style={styles.title}>Home</Text>
        <Text style={styles.text}>All offers. Tap a moodboard to filter.</Text>

        <ScrollView horizontal style={styles.horizontalList}>
          <Pressable style={styles.chip} onPress={() => setActiveBoardFilter(null)}>
            <Text>{activeBoardFilter ? "All" : "[All]"}</Text>
          </Pressable>
          {selectedBoards.map((board) => (
            <Pressable key={board.id} style={styles.chip} onPress={() => setActiveBoardFilter(board.id)}>
              <Text>{activeBoardFilter === board.id ? `[${board.name}]` : board.name}</Text>
            </Pressable>
          ))}
        </ScrollView>

        {visibleProducts.map((product) => (
          <Pressable key={product.id} style={styles.card} onPress={() => openProduct(product)}>
            <Text>{product.title}</Text>
            <Text>{product.price} · {product.shop}</Text>
          </Pressable>
        ))}
      </View>
    );
  }

  function renderMoodboardsTab() {
    return (
      <View style={styles.block}>
        <Text style={styles.title}>Moodboards</Text>
        {selectedBoards.map((board) => (
          <View key={board.id} style={styles.card}>
            <Text>{board.name}</Text>
            <Text>Filters: Designer / Brands / Price / Country / Quality</Text>
          </View>
        ))}
      </View>
    );
  }

  function renderArchiveTab() {
    return (
      <View style={styles.block}>
        <Text style={styles.title}>Archive</Text>
        {archivedProductsByBoard.map(({ board, products }) => (
          <View key={board.id} style={styles.card}>
            <Text>{board.name}</Text>
            {products.length === 0 ? <Text>No archived products.</Text> : null}
            {products.map((product) => (
              <Text key={product.id}>- {product.title}</Text>
            ))}
          </View>
        ))}
      </View>
    );
  }

  function renderAppArea() {
    if (appScreen === "settings") {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Settings</Text>
          <Text style={styles.text}>Language: English</Text>
          <Text style={styles.text}>Notifications: New matches</Text>
          <Text style={styles.text}>Privacy: Recommendation data enabled</Text>
          <Pressable style={styles.button} onPress={() => setAppScreen("app") }>
            <Text style={styles.buttonText}>Back</Text>
          </Pressable>
        </View>
      );
    }

    if (appScreen === "product-detail" && selectedProduct) {
      return (
        <View style={styles.block}>
          <Text style={styles.title}>Product Detail</Text>
          <Text style={styles.text}>{selectedProduct.title}</Text>
          <Text style={styles.text}>{selectedProduct.price} · {selectedProduct.shop}</Text>

          <Pressable style={styles.button} onPress={() => Alert.alert("Buy now", "Would open shop with selected size/variant.") }>
            <Text style={styles.buttonText}>Buy now</Text>
          </Pressable>

          <View style={styles.row}>
            <Pressable style={styles.buttonSecondary} onPress={() => Alert.alert("Feedback", "Liked") }>
              <Text>Like</Text>
            </Pressable>
            <Pressable style={styles.buttonSecondary} onPress={() => Alert.alert("Feedback", "Disliked") }>
              <Text>Dislike</Text>
            </Pressable>
            <Pressable style={styles.buttonSecondary} onPress={() => toggleArchive(selectedProduct.id)}>
              <Text>{archivedProductIds[selectedProduct.id] ? "Unarchive" : "Archive"}</Text>
            </Pressable>
          </View>

          <Pressable style={styles.button} onPress={() => setAppScreen("app") }>
            <Text style={styles.buttonText}>Back to Feed</Text>
          </Pressable>
        </View>
      );
    }

    return (
      <View style={styles.block}>
        <View style={styles.headerRow}>
          <Text style={styles.title}>StyleMatch MVP Flow</Text>
          <Pressable style={styles.buttonSecondary} onPress={() => setAppScreen("settings") }>
            <Text>Profile</Text>
          </Pressable>
        </View>

        {activeTab === "home" ? renderHomeTab() : null}
        {activeTab === "moodboards" ? renderMoodboardsTab() : null}
        {activeTab === "archive" ? renderArchiveTab() : null}

        <View style={styles.tabs}>
          <Pressable style={styles.tabButton} onPress={() => setActiveTab("home")}>
            <Text>{activeTab === "home" ? "[Home]" : "Home"}</Text>
          </Pressable>
          <Pressable style={styles.tabButton} onPress={() => setActiveTab("moodboards")}>
            <Text>{activeTab === "moodboards" ? "[Moodboards]" : "Moodboards"}</Text>
          </Pressable>
          <Pressable style={styles.tabButton} onPress={() => setActiveTab("archive")}>
            <Text>{activeTab === "archive" ? "[Archive]" : "Archive"}</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  const showSetup = !isLoggedIn || setupScreen !== "intro-1";

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar style="dark" />
      <ScrollView contentContainerStyle={styles.content}>
        {showSetup ? renderSetupFlow() : renderAppArea()}

        <Pressable style={styles.resetButton} onPress={resetToSetup}>
          <Text>Reset full flow</Text>
        </Pressable>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  content: { padding: 16, gap: 12 },
  block: { gap: 10 },
  title: { fontSize: 22, fontWeight: "700" },
  text: { fontSize: 15 },
  input: {
    borderWidth: 1,
    borderColor: "#999",
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8
  },
  button: {
    backgroundColor: "#222",
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 10,
    alignSelf: "flex-start"
  },
  buttonText: { color: "#fff", fontWeight: "600" },
  buttonSecondary: {
    borderWidth: 1,
    borderColor: "#999",
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    alignSelf: "flex-start"
  },
  row: { flexDirection: "row", gap: 8, flexWrap: "wrap" },
  list: { maxHeight: 220, borderWidth: 1, borderColor: "#ddd", borderRadius: 8 },
  listItem: {
    paddingHorizontal: 10,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: "#eee"
  },
  horizontalList: { maxHeight: 45 },
  chip: {
    borderWidth: 1,
    borderColor: "#999",
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginRight: 8
  },
  card: {
    borderWidth: 1,
    borderColor: "#bbb",
    borderRadius: 8,
    padding: 10,
    gap: 4
  },
  headerRow: { flexDirection: "row", justifyContent: "space-between", alignItems: "center" },
  tabs: {
    flexDirection: "row",
    justifyContent: "space-around",
    borderTopWidth: 1,
    borderTopColor: "#ddd",
    paddingTop: 10,
    marginTop: 12
  },
  tabButton: {
    borderWidth: 1,
    borderColor: "#aaa",
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8
  },
  resetButton: {
    marginTop: 12,
    borderWidth: 1,
    borderColor: "#aaa",
    borderRadius: 8,
    paddingHorizontal: 10,
    paddingVertical: 8,
    alignSelf: "flex-start"
  }
});

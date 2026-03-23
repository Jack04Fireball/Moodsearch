import { StatusBar } from "expo-status-bar";
import { useMemo, useState } from "react";
import {
  Alert,
  FlatList,
  Pressable,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useWindowDimensions,
} from "react-native";

type FlowStage = "intro" | "connect" | "boards" | "setup" | "analyzing" | "app";
type MainTab = "home" | "moodboards" | "archive";
type Reaction = "like" | "dislike";

type Moodboard = {
  id: string;
  name: string;
  pinCount: number;
};

type Offer = {
  id: string;
  boardId: string;
  title: string;
  brand: string;
  designer: string;
  price: number;
  shop: string;
  quality: "premium" | "standard";
  country: "CH" | "IT" | "FR" | "JP" | "EU";
};

type BoardSettings = {
  focusDesigners: string[];
  focusBrands: string[];
  minPrice: number;
  maxPrice: number;
  quality: "all" | "premium" | "standard";
  country: "all" | "CH" | "EU";
};

const BUILD_MARKER = "Build 2006 - Wireframe Gray";

const PALETTE = {
  bg: "#F6F6F6",
  surface: "#FFFFFF",
  border: "#E6E6E6",
  text: "#121212",
  textSoft: "#707070",
  accent: "#6F6F6F",
  accentText: "#FFFFFF",
  chip: "#E3E3E3",
  chipActive: "#7A7A7A",
  chipActiveText: "#FFFFFF",
  placeholder: "#CFCFCF",
  placeholderDark: "#B8B8B8",
};

const INTRO_SLIDES = [
  "Pinterest-inspired shopping flow with board-based intelligence.",
  "Every visual is a gray placeholder so we can test structure only.",
  "You can start from zero every time and test the full journey.",
];

const BOARDS: Moodboard[] = [
  { id: "b1", name: "City Minimal", pinCount: 124 },
  { id: "b2", name: "Quiet Luxury", pinCount: 92 },
  { id: "b3", name: "Street Layering", pinCount: 151 },
  { id: "b4", name: "Tailored Archive", pinCount: 88 },
  { id: "b5", name: "Soft Evening", pinCount: 67 },
  { id: "b6", name: "Daily Uniform", pinCount: 118 },
];

const OFFERS: Offer[] = [
  {
    id: "o1",
    boardId: "b1",
    title: "Relaxed Wool Coat",
    brand: "COS",
    designer: "Lemaire",
    price: 540,
    shop: "Browns",
    quality: "premium",
    country: "IT",
  },
  {
    id: "o2",
    boardId: "b1",
    title: "Straight Pleated Pant",
    brand: "Arket",
    designer: "Jil Sander",
    price: 210,
    shop: "Arket",
    quality: "standard",
    country: "CH",
  },
  {
    id: "o3",
    boardId: "b2",
    title: "Leather Loafer",
    brand: "Aeyde",
    designer: "The Row",
    price: 690,
    shop: "Mytheresa",
    quality: "premium",
    country: "IT",
  },
  {
    id: "o4",
    boardId: "b2",
    title: "Silk Blend Shirt",
    brand: "Toteme",
    designer: "Phoebe Philo",
    price: 410,
    shop: "Net-a-Porter",
    quality: "premium",
    country: "FR",
  },
  {
    id: "o5",
    boardId: "b3",
    title: "Oversized Bomber",
    brand: "Acne Studios",
    designer: "Demna",
    price: 980,
    shop: "SSENSE",
    quality: "premium",
    country: "JP",
  },
  {
    id: "o6",
    boardId: "b3",
    title: "Utility Trouser",
    brand: "Weekday",
    designer: "Martine Rose",
    price: 220,
    shop: "Weekday",
    quality: "standard",
    country: "CH",
  },
  {
    id: "o7",
    boardId: "b4",
    title: "Double Blazer",
    brand: "Massimo Dutti",
    designer: "Haider Ackermann",
    price: 360,
    shop: "Massimo Dutti",
    quality: "standard",
    country: "IT",
  },
  {
    id: "o8",
    boardId: "b4",
    title: "Merino Turtleneck",
    brand: "Uniqlo",
    designer: "Dries Van Noten",
    price: 120,
    shop: "Uniqlo",
    quality: "standard",
    country: "EU",
  },
  {
    id: "o9",
    boardId: "b5",
    title: "Evening Heel",
    brand: "Amina Muaddi",
    designer: "Tom Ford",
    price: 840,
    shop: "Browns",
    quality: "premium",
    country: "IT",
  },
  {
    id: "o10",
    boardId: "b6",
    title: "Heavy Cotton Tee",
    brand: "Sunspel",
    designer: "Margiela",
    price: 95,
    shop: "Sunspel",
    quality: "standard",
    country: "CH",
  },
  {
    id: "o11",
    boardId: "b6",
    title: "Clean Sneaker",
    brand: "Common Projects",
    designer: "Hedi Slimane",
    price: 470,
    shop: "Farfetch",
    quality: "premium",
    country: "IT",
  },
  {
    id: "o12",
    boardId: "b5",
    title: "Sharp Velvet Jacket",
    brand: "Saint Laurent",
    designer: "Vaccarello",
    price: 1450,
    shop: "Saint Laurent",
    quality: "premium",
    country: "FR",
  },
];

const DESIGNER_SUGGESTIONS = [
  "Jil Sander",
  "Phoebe Philo",
  "The Row",
  "Demna",
  "Lemaire",
  "Margiela",
  "Dries Van Noten",
];

const BRAND_SUGGESTIONS = [
  "COS",
  "Arket",
  "Toteme",
  "Aeyde",
  "Acne Studios",
  "Weekday",
  "Uniqlo",
  "Saint Laurent",
];

function clamp(value: number, min: number, max: number) {
  return Math.min(max, Math.max(min, value));
}

function defaultSettingsForBoards(boardIds: string[]): Record<string, BoardSettings> {
  return boardIds.reduce<Record<string, BoardSettings>>((acc, boardId) => {
    acc[boardId] = {
      focusDesigners: [],
      focusBrands: [],
      minPrice: 200,
      maxPrice: 2000,
      quality: "all",
      country: "all",
    };
    return acc;
  }, {});
}

function PlaceholderBlock({ height, radius = 14 }: { height: number; radius?: number }) {
  return (
    <View
      style={{
        height,
        borderRadius: radius,
        backgroundColor: PALETTE.placeholder,
      }}
    />
  );
}

export default function App() {
  const { width } = useWindowDimensions();

  const [flowStage, setFlowStage] = useState<FlowStage>("intro");
  const [slideIndex, setSlideIndex] = useState(0);

  const [boardSearch, setBoardSearch] = useState("");
  const [selectedBoardIds, setSelectedBoardIds] = useState<string[]>([]);
  const [size, setSize] = useState("M");
  const [globalMin, setGlobalMin] = useState(200);
  const [globalMax, setGlobalMax] = useState(2000);

  const [boardSettings, setBoardSettings] = useState<Record<string, BoardSettings>>({});
  const [activeTab, setActiveTab] = useState<MainTab>("home");
  const [activeBoardFilter, setActiveBoardFilter] = useState<string | "all">("all");

  const [openedOfferId, setOpenedOfferId] = useState<string | null>(null);
  const [archivedOfferIds, setArchivedOfferIds] = useState<string[]>([]);
  const [offerReactions, setOfferReactions] = useState<Record<string, Reaction>>({});

  const [openedMoodboardId, setOpenedMoodboardId] = useState<string | null>(null);
  const [customDesigner, setCustomDesigner] = useState("");

  const selectedBoards = useMemo(
    () => BOARDS.filter((board) => selectedBoardIds.includes(board.id)),
    [selectedBoardIds]
  );

  const visibleBoardCandidates = useMemo(() => {
    const q = boardSearch.trim().toLowerCase();
    if (!q) return BOARDS;
    return BOARDS.filter((b) => b.name.toLowerCase().includes(q));
  }, [boardSearch]);

  const visibleOffers = useMemo(() => {
    return OFFERS.filter((offer) => {
      if (!selectedBoardIds.includes(offer.boardId)) return false;
      if (activeBoardFilter !== "all" && offer.boardId !== activeBoardFilter) return false;

      const setting = boardSettings[offer.boardId];
      if (!setting) return false;

      if (offer.price < setting.minPrice || offer.price > setting.maxPrice) return false;
      if (setting.quality !== "all" && offer.quality !== setting.quality) return false;

      if (setting.country === "CH" && offer.country !== "CH") return false;
      if (setting.country === "EU" && !["IT", "FR"].includes(offer.country)) return false;

      if (setting.focusDesigners.length > 0 && !setting.focusDesigners.includes(offer.designer)) {
        return false;
      }
      if (setting.focusBrands.length > 0 && !setting.focusBrands.includes(offer.brand)) {
        return false;
      }

      return true;
    });
  }, [activeBoardFilter, boardSettings, selectedBoardIds]);

  const archivedOffers = useMemo(
    () => OFFERS.filter((offer) => archivedOfferIds.includes(offer.id)),
    [archivedOfferIds]
  );

  const openedOffer = useMemo(
    () => OFFERS.find((offer) => offer.id === openedOfferId) ?? null,
    [openedOfferId]
  );

  const openedMoodboard = useMemo(
    () => BOARDS.find((board) => board.id === openedMoodboardId) ?? null,
    [openedMoodboardId]
  );

  function resetEverything() {
    setFlowStage("intro");
    setSlideIndex(0);
    setBoardSearch("");
    setSelectedBoardIds([]);
    setSize("M");
    setGlobalMin(200);
    setGlobalMax(2000);
    setBoardSettings({});
    setActiveTab("home");
    setActiveBoardFilter("all");
    setOpenedOfferId(null);
    setArchivedOfferIds([]);
    setOfferReactions({});
    setOpenedMoodboardId(null);
    setCustomDesigner("");
  }

  function nextIntroSlide() {
    if (slideIndex < INTRO_SLIDES.length - 1) {
      setSlideIndex((v) => v + 1);
      return;
    }
    setFlowStage("connect");
  }

  function toggleBoardSelection(boardId: string) {
    setSelectedBoardIds((prev) => {
      if (prev.includes(boardId)) {
        if (activeBoardFilter === boardId) {
          setActiveBoardFilter("all");
        }
        return prev.filter((id) => id !== boardId);
      }
      if (prev.length >= 10) {
        Alert.alert("Limit", "Please select max 10 moodboards.");
        return prev;
      }
      return [...prev, boardId];
    });
  }

  function continueFromBoards() {
    if (selectedBoardIds.length < 1) {
      Alert.alert("Missing selection", "Please select at least one moodboard.");
      return;
    }
    setBoardSettings(defaultSettingsForBoards(selectedBoardIds));
    setFlowStage("setup");
  }

  function adjustGlobalRange(which: "min" | "max", delta: number) {
    if (which === "min") {
      setGlobalMin((current) => {
        const next = clamp(current + delta, 0, 7000);
        return Math.min(next, globalMax - 50);
      });
      return;
    }

    setGlobalMax((current) => {
      const next = clamp(current + delta, 100, 9000);
      return Math.max(next, globalMin + 50);
    });
  }

  function continueFromSetup() {
    const nextSettings = { ...boardSettings };
    selectedBoardIds.forEach((boardId) => {
      const current = nextSettings[boardId];
      if (!current) return;
      nextSettings[boardId] = {
        ...current,
        minPrice: globalMin,
        maxPrice: globalMax,
      };
    });

    setBoardSettings(nextSettings);
    setFlowStage("analyzing");
  }

  function openMainApp() {
    setFlowStage("app");
    setActiveTab("home");
    setActiveBoardFilter("all");
  }

  function toggleArchive(offerId: string) {
    setArchivedOfferIds((prev) =>
      prev.includes(offerId) ? prev.filter((id) => id !== offerId) : [...prev, offerId]
    );
  }

  function updateReaction(offerId: string, reaction: Reaction) {
    setOfferReactions((prev) => ({ ...prev, [offerId]: reaction }));
  }

  function updateBoardSettings(boardId: string, updater: (curr: BoardSettings) => BoardSettings) {
    setBoardSettings((prev) => {
      const current = prev[boardId];
      if (!current) return prev;
      return { ...prev, [boardId]: updater(current) };
    });
  }

  function toggleFocus(boardId: string, kind: "designer" | "brand", value: string) {
    updateBoardSettings(boardId, (current) => {
      const target = kind === "designer" ? current.focusDesigners : current.focusBrands;
      const exists = target.includes(value);
      const next = exists ? target.filter((x) => x !== value) : [...target, value];
      return kind === "designer"
        ? { ...current, focusDesigners: next }
        : { ...current, focusBrands: next };
    });
  }

  function addDesigner(boardId: string) {
    const value = customDesigner.trim();
    if (!value) return;

    updateBoardSettings(boardId, (current) => {
      if (current.focusDesigners.includes(value)) return current;
      return { ...current, focusDesigners: [...current.focusDesigners, value] };
    });
    setCustomDesigner("");
  }

  function adjustBoardRange(boardId: string, which: "min" | "max", delta: number) {
    updateBoardSettings(boardId, (current) => {
      if (which === "min") {
        const min = clamp(current.minPrice + delta, 0, 7000);
        return { ...current, minPrice: Math.min(min, current.maxPrice - 50) };
      }
      const max = clamp(current.maxPrice + delta, 100, 9000);
      return { ...current, maxPrice: Math.max(max, current.minPrice + 50) };
    });
  }

  function renderIntro() {
    return (
      <View style={styles.flowCard}>
        <Text style={styles.heroTitle}>StyleMatch</Text>
        <Text style={styles.heroSubtitle}>Pinterest-like prototype flow</Text>
        <Text style={styles.bodySoft}>{BUILD_MARKER}</Text>

        <PlaceholderBlock height={220} radius={20} />

        <Text style={styles.bodyText}>{INTRO_SLIDES[slideIndex]}</Text>

        <View style={styles.dotsRow}>
          {INTRO_SLIDES.map((_, idx) => (
            <View
              key={`intro_dot_${idx}`}
              style={[
                styles.dot,
                idx === slideIndex ? styles.dotActive : styles.dotInactive,
              ]}
            />
          ))}
        </View>

        <Pressable style={styles.primaryButton} onPress={nextIntroSlide}>
          <Text style={styles.primaryButtonText}>
            {slideIndex === INTRO_SLIDES.length - 1 ? "Continue" : "Next"}
          </Text>
        </Pressable>
      </View>
    );
  }

  function renderConnect() {
    return (
      <View style={styles.flowCard}>
        <Text style={styles.heroTitle}>Connect Pinterest</Text>
        <Text style={styles.bodySoft}>Prototype connection screen</Text>

        <View style={styles.connectCard}>
          <View style={styles.connectAvatar} />
          <View style={{ flex: 1, gap: 8 }}>
            <PlaceholderBlock height={14} radius={7} />
            <View style={{ width: "65%" }}>
              <PlaceholderBlock height={12} radius={7} />
            </View>
          </View>
        </View>

        <View style={styles.connectCard}>
          <PlaceholderBlock height={120} radius={14} />
          <Text style={styles.bodySoft}>All feed photos are replaced by gray placeholders.</Text>
        </View>

        <Pressable style={styles.primaryButton} onPress={() => setFlowStage("boards")}>
          <Text style={styles.primaryButtonText}>Connect (Prototype)</Text>
        </Pressable>
      </View>
    );
  }

  function renderBoardsSelection() {
    return (
      <View style={styles.flowCard}>
        <Text style={styles.heroTitle}>Select Moodboards</Text>
        <Text style={styles.bodySoft}>Search by board name. Choose 1 to 10 boards.</Text>

        <TextInput
          value={boardSearch}
          onChangeText={setBoardSearch}
          placeholder="Search board name"
          placeholderTextColor="#8A8A8A"
          style={styles.searchInput}
        />

        <FlatList
          data={visibleBoardCandidates}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={false}
          style={{ maxHeight: 360 }}
          renderItem={({ item }) => {
            const selected = selectedBoardIds.includes(item.id);
            return (
              <Pressable
                style={[
                  styles.boardListItem,
                  selected && { borderColor: PALETTE.accent, borderWidth: 2 },
                ]}
                onPress={() => toggleBoardSelection(item.id)}
              >
                <View style={styles.boardListThumb} />
                <View style={{ flex: 1, gap: 2 }}>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  <Text style={styles.bodySoft}>{item.pinCount} Pins</Text>
                </View>
                <View style={[styles.tagPill, selected && styles.tagPillActive]}>
                  <Text style={[styles.tagPillText, selected && styles.tagPillTextActive]}>
                    {selected ? "Selected" : "Tap"}
                  </Text>
                </View>
              </Pressable>
            );
          }}
        />

        <Text style={styles.bodySoft}>Selected: {selectedBoardIds.length}</Text>

        <Pressable style={styles.primaryButton} onPress={continueFromBoards}>
          <Text style={styles.primaryButtonText}>Continue</Text>
        </Pressable>
      </View>
    );
  }

  function renderSetup() {
    return (
      <View style={styles.flowCard}>
        <Text style={styles.heroTitle}>Global Preferences</Text>
        <Text style={styles.bodySoft}>These values are copied into each selected moodboard.</Text>

        <View style={styles.inputGroup}>
          <Text style={styles.fieldLabel}>Size</Text>
          <TextInput
            value={size}
            onChangeText={setSize}
            placeholder="M"
            placeholderTextColor="#8A8A8A"
            style={styles.searchInput}
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.fieldLabel}>Price Range (CHF)</Text>
          <View style={styles.rangeCard}>
            <View style={styles.rangeTrackBase}>
              <View
                style={[
                  styles.rangeTrackActive,
                  {
                    left: `${(globalMin / 5000) * 100}%`,
                    right: `${100 - (globalMax / 5000) * 100}%`,
                  },
                ]}
              />
            </View>
            <Text style={styles.cardTitle}>
              {globalMin} - {globalMax} CHF
            </Text>
            <View style={styles.inlineButtons}>
              <Pressable style={styles.smallBtn} onPress={() => adjustGlobalRange("min", -50)}>
                <Text style={styles.smallBtnText}>Min -50</Text>
              </Pressable>
              <Pressable style={styles.smallBtn} onPress={() => adjustGlobalRange("min", 50)}>
                <Text style={styles.smallBtnText}>Min +50</Text>
              </Pressable>
              <Pressable style={styles.smallBtn} onPress={() => adjustGlobalRange("max", -50)}>
                <Text style={styles.smallBtnText}>Max -50</Text>
              </Pressable>
              <Pressable style={styles.smallBtn} onPress={() => adjustGlobalRange("max", 50)}>
                <Text style={styles.smallBtnText}>Max +50</Text>
              </Pressable>
            </View>
          </View>
        </View>

        <Pressable style={styles.primaryButton} onPress={continueFromSetup}>
          <Text style={styles.primaryButtonText}>Start Analysis</Text>
        </Pressable>
      </View>
    );
  }

  function renderAnalyzing() {
    return (
      <View style={styles.flowCard}>
        <Text style={styles.heroTitle}>Analyzing Moodboards</Text>
        <Text style={styles.bodySoft}>Prototype: style vectors and offer feed are ready.</Text>

        <View style={styles.progressCard}>
          <Text style={styles.bodySoft}>Reading board language</Text>
          <View style={styles.progressBar}>
            <View style={styles.progressBarFill} />
          </View>

          <Text style={styles.bodySoft}>Matching products</Text>
          <View style={styles.progressBar}>
            <View style={styles.progressBarFill} />
          </View>

          <Text style={styles.bodySoft}>Building home feed</Text>
          <View style={styles.progressBar}>
            <View style={styles.progressBarFill} />
          </View>
        </View>

        <Pressable style={styles.primaryButton} onPress={openMainApp}>
          <Text style={styles.primaryButtonText}>Open Prototype</Text>
        </Pressable>
      </View>
    );
  }

  function renderHome() {
    const gap = 10;
    const cardWidth = (width - 16 * 2 - 12 * 2 - gap) / 2;

    return (
      <View style={styles.tabBody}>
        <View style={styles.headerRow}>
          <Text style={styles.sectionTitle}>Home</Text>
          <Text style={styles.bodySoft}>New finds</Text>
        </View>

        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={{ maxHeight: 46 }}>
          <Pressable
            style={[styles.filterChip, activeBoardFilter === "all" && styles.filterChipActive]}
            onPress={() => setActiveBoardFilter("all")}
          >
            <Text
              style={[
                styles.filterChipText,
                activeBoardFilter === "all" && styles.filterChipTextActive,
              ]}
            >
              All
            </Text>
          </Pressable>
          {selectedBoards.map((board) => {
            const active = activeBoardFilter === board.id;
            return (
              <Pressable
                key={board.id}
                style={[styles.filterChip, active && styles.filterChipActive]}
                onPress={() => setActiveBoardFilter(board.id)}
              >
                <Text style={[styles.filterChipText, active && styles.filterChipTextActive]}>
                  {board.name}
                </Text>
              </Pressable>
            );
          })}
        </ScrollView>

        <FlatList
          data={visibleOffers}
          keyExtractor={(item) => item.id}
          numColumns={2}
          showsVerticalScrollIndicator={false}
          columnWrapperStyle={{ gap }}
          contentContainerStyle={{ gap, paddingBottom: 24 }}
          renderItem={({ item, index }) => {
            const imageHeight = index % 4 === 0 ? 210 : index % 4 === 1 ? 160 : index % 4 === 2 ? 190 : 145;
            return (
              <Pressable style={[styles.pinCard, { width: cardWidth }]} onPress={() => setOpenedOfferId(item.id)}>
                <View style={[styles.pinImage, { height: imageHeight }]} />
                <View style={styles.pinTextWrap}>
                  <Text style={styles.cardTitle} numberOfLines={2}>
                    {item.title}
                  </Text>
                  <Text style={styles.bodySoft} numberOfLines={1}>
                    {item.brand} · {item.designer}
                  </Text>
                  <Text style={styles.cardPrice}>CHF {item.price}</Text>
                </View>
              </Pressable>
            );
          }}
          ListEmptyComponent={
            <View style={styles.emptyStateCard}>
              <Text style={styles.bodyText}>No offers for current filters.</Text>
              <Text style={styles.bodySoft}>Try another moodboard filter or price range.</Text>
            </View>
          }
        />
      </View>
    );
  }

  function renderMoodboards() {
    const gap = 10;
    const cardWidth = (width - 16 * 2 - 12 * 2 - gap) / 2;

    return (
      <View style={styles.tabBody}>
        <View style={styles.headerRow}>
          <Text style={styles.sectionTitle}>Moodboards</Text>
          <Text style={styles.bodySoft}>Pinterest-style board grid</Text>
        </View>

        <FlatList
          data={selectedBoards}
          keyExtractor={(item) => item.id}
          numColumns={2}
          showsVerticalScrollIndicator={false}
          columnWrapperStyle={{ gap }}
          contentContainerStyle={{ gap, paddingBottom: 24 }}
          renderItem={({ item, index }) => {
            const imageHeight = index % 2 === 0 ? 180 : 220;
            const purchasedCount = archivedOffers.filter((o) => o.boardId === item.id).length;
            return (
              <Pressable
                style={[styles.pinCard, { width: cardWidth }]}
                onPress={() => setOpenedMoodboardId(item.id)}
              >
                <View style={[styles.pinImage, { height: imageHeight }]} />
                <View style={styles.pinTextWrap}>
                  <Text style={styles.cardTitle}>{item.name}</Text>
                  <Text style={styles.bodySoft}>{item.pinCount} Pins</Text>
                  <Text style={styles.bodySoft}>Purchases: {purchasedCount}</Text>
                </View>
              </Pressable>
            );
          }}
        />
      </View>
    );
  }

  function renderArchive() {
    return (
      <View style={styles.tabBody}>
        <View style={styles.headerRow}>
          <Text style={styles.sectionTitle}>Archive</Text>
          <Text style={styles.bodySoft}>Saved for later</Text>
        </View>

        <FlatList
          data={archivedOffers}
          keyExtractor={(item) => item.id}
          showsVerticalScrollIndicator={false}
          contentContainerStyle={{ gap: 10, paddingBottom: 24 }}
          renderItem={({ item }) => (
            <View style={styles.archiveRow}>
              <View style={styles.archiveThumb} />
              <View style={{ flex: 1, gap: 2 }}>
                <Text style={styles.cardTitle}>{item.title}</Text>
                <Text style={styles.bodySoft}>{item.brand} · {item.designer}</Text>
                <Text style={styles.bodySoft}>CHF {item.price} · {item.shop}</Text>
              </View>
            </View>
          )}
          ListEmptyComponent={
            <View style={styles.emptyStateCard}>
              <Text style={styles.bodyText}>Archive is empty.</Text>
              <Text style={styles.bodySoft}>Open an offer and tap Archive.</Text>
            </View>
          }
        />
      </View>
    );
  }

  function renderOfferDetail() {
    if (!openedOffer) return null;

    const reaction = offerReactions[openedOffer.id];
    const isArchived = archivedOfferIds.includes(openedOffer.id);

    return (
      <View style={styles.detailScreen}>
        <Pressable style={styles.backBtn} onPress={() => setOpenedOfferId(null)}>
          <Text style={styles.backBtnText}>Back</Text>
        </Pressable>

        <View style={{ marginTop: 10 }}>
          <PlaceholderBlock height={340} radius={18} />
        </View>

        <View style={{ gap: 4, marginTop: 12 }}>
          <Text style={styles.sectionTitle}>{openedOffer.title}</Text>
          <Text style={styles.bodyText}>{openedOffer.brand} · {openedOffer.designer}</Text>
          <Text style={styles.bodySoft}>CHF {openedOffer.price} · {openedOffer.shop}</Text>
        </View>

        <Pressable
          style={styles.primaryButton}
          onPress={() => Alert.alert("Prototype", `Open product in size ${size} and go to checkout.`)}
        >
          <Text style={styles.primaryButtonText}>Open in matching size</Text>
        </Pressable>

        <View style={styles.inlineButtons}>
          <Pressable
            style={[styles.smallBtn, reaction === "like" && styles.smallBtnActive]}
            onPress={() => updateReaction(openedOffer.id, "like")}
          >
            <Text style={[styles.smallBtnText, reaction === "like" && styles.smallBtnTextActive]}>Like</Text>
          </Pressable>
          <Pressable
            style={[styles.smallBtn, reaction === "dislike" && styles.smallBtnActive]}
            onPress={() => updateReaction(openedOffer.id, "dislike")}
          >
            <Text style={[styles.smallBtnText, reaction === "dislike" && styles.smallBtnTextActive]}>
              Dislike
            </Text>
          </Pressable>
          <Pressable style={styles.smallBtn} onPress={() => toggleArchive(openedOffer.id)}>
            <Text style={styles.smallBtnText}>{isArchived ? "Unarchive" : "Archive"}</Text>
          </Pressable>
        </View>
      </View>
    );
  }

  function renderMoodboardDetail() {
    if (!openedMoodboard) return null;

    const setting = boardSettings[openedMoodboard.id];
    if (!setting) return null;

    const pageWidth = width - 16 * 2 - 12 * 2;
    const boardOffers = archivedOffers.filter((o) => o.boardId === openedMoodboard.id);
    const pinItems = Array.from({ length: 18 }).map((_, idx) => ({ id: `${openedMoodboard.id}_pin_${idx}` }));

    return (
      <View style={styles.detailScreen}>
        <View style={styles.headerRow}>
          <Pressable style={styles.backBtn} onPress={() => setOpenedMoodboardId(null)}>
            <Text style={styles.backBtnText}>Back</Text>
          </Pressable>
          <Text style={styles.bodySoft}>Swipe pages</Text>
        </View>

        <Text style={styles.sectionTitle}>{openedMoodboard.name}</Text>

        <ScrollView
          horizontal
          pagingEnabled
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={{ gap: 10 }}
        >
          <View style={[styles.boardPage, { width: pageWidth }]}>
            <Text style={styles.pageTitle}>Pins</Text>
            <FlatList
              data={pinItems}
              keyExtractor={(item) => item.id}
              numColumns={2}
              showsVerticalScrollIndicator={false}
              columnWrapperStyle={{ gap: 8 }}
              contentContainerStyle={{ gap: 8, paddingBottom: 8 }}
              renderItem={({ item, index }) => (
                <View style={{ flex: 1 }}>
                  <PlaceholderBlock
                    height={index % 3 === 0 ? 160 : index % 3 === 1 ? 115 : 145}
                    radius={12}
                  />
                </View>
              )}
            />
          </View>

          <View style={[styles.boardPage, { width: pageWidth }]}>
            <Text style={styles.pageTitle}>Purchases</Text>
            {boardOffers.length === 0 ? (
              <View style={styles.emptyStateCard}>
                <Text style={styles.bodyText}>No purchases yet.</Text>
              </View>
            ) : (
              <FlatList
                data={boardOffers}
                keyExtractor={(item) => item.id}
                contentContainerStyle={{ gap: 8 }}
                renderItem={({ item }) => (
                  <View style={styles.archiveRow}>
                    <View style={styles.archiveThumb} />
                    <View style={{ flex: 1, gap: 2 }}>
                      <Text style={styles.cardTitle}>{item.title}</Text>
                      <Text style={styles.bodySoft}>CHF {item.price} · {item.shop}</Text>
                    </View>
                  </View>
                )}
              />
            )}
          </View>

          <View style={[styles.boardPage, { width: pageWidth }]}>
            <Text style={styles.pageTitle}>Settings</Text>
            <Text style={styles.bodySoft}>Designer/brand choices are focus signals, not hard-locks.</Text>

            <Text style={styles.fieldLabel}>Focus Designers</Text>
            <View style={styles.wrapRow}>
              {DESIGNER_SUGGESTIONS.map((designer) => {
                const active = setting.focusDesigners.includes(designer);
                return (
                  <Pressable
                    key={designer}
                    style={[styles.filterChip, active && styles.filterChipActive]}
                    onPress={() => toggleFocus(openedMoodboard.id, "designer", designer)}
                  >
                    <Text style={[styles.filterChipText, active && styles.filterChipTextActive]}>
                      {designer}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            <View style={styles.customRow}>
              <TextInput
                value={customDesigner}
                onChangeText={setCustomDesigner}
                placeholder="Add designer"
                placeholderTextColor="#8A8A8A"
                style={[styles.searchInput, { flex: 1 }]}
              />
              <Pressable style={styles.addBtn} onPress={() => addDesigner(openedMoodboard.id)}>
                <Text style={styles.addBtnText}>Add</Text>
              </Pressable>
            </View>

            <Text style={styles.fieldLabel}>Focus Brands</Text>
            <View style={styles.wrapRow}>
              {BRAND_SUGGESTIONS.map((brand) => {
                const active = setting.focusBrands.includes(brand);
                return (
                  <Pressable
                    key={brand}
                    style={[styles.filterChip, active && styles.filterChipActive]}
                    onPress={() => toggleFocus(openedMoodboard.id, "brand", brand)}
                  >
                    <Text style={[styles.filterChipText, active && styles.filterChipTextActive]}>{brand}</Text>
                  </Pressable>
                );
              })}
            </View>

            <Text style={styles.fieldLabel}>Price Range (CHF)</Text>
            <View style={styles.rangeCard}>
              <Text style={styles.cardTitle}>
                {setting.minPrice} - {setting.maxPrice}
              </Text>
              <View style={styles.inlineButtons}>
                <Pressable
                  style={styles.smallBtn}
                  onPress={() => adjustBoardRange(openedMoodboard.id, "min", -50)}
                >
                  <Text style={styles.smallBtnText}>Min -50</Text>
                </Pressable>
                <Pressable
                  style={styles.smallBtn}
                  onPress={() => adjustBoardRange(openedMoodboard.id, "min", 50)}
                >
                  <Text style={styles.smallBtnText}>Min +50</Text>
                </Pressable>
                <Pressable
                  style={styles.smallBtn}
                  onPress={() => adjustBoardRange(openedMoodboard.id, "max", -50)}
                >
                  <Text style={styles.smallBtnText}>Max -50</Text>
                </Pressable>
                <Pressable
                  style={styles.smallBtn}
                  onPress={() => adjustBoardRange(openedMoodboard.id, "max", 50)}
                >
                  <Text style={styles.smallBtnText}>Max +50</Text>
                </Pressable>
              </View>
            </View>

            <Text style={styles.fieldLabel}>Quality</Text>
            <View style={styles.wrapRow}>
              {(["all", "premium", "standard"] as const).map((quality) => {
                const active = setting.quality === quality;
                return (
                  <Pressable
                    key={quality}
                    style={[styles.filterChip, active && styles.filterChipActive]}
                    onPress={() => updateBoardSettings(openedMoodboard.id, (curr) => ({ ...curr, quality }))}
                  >
                    <Text style={[styles.filterChipText, active && styles.filterChipTextActive]}>
                      {quality}
                    </Text>
                  </Pressable>
                );
              })}
            </View>

            <Text style={styles.fieldLabel}>Country</Text>
            <View style={styles.wrapRow}>
              {(["all", "CH", "EU"] as const).map((country) => {
                const active = setting.country === country;
                return (
                  <Pressable
                    key={country}
                    style={[styles.filterChip, active && styles.filterChipActive]}
                    onPress={() => updateBoardSettings(openedMoodboard.id, (curr) => ({ ...curr, country }))}
                  >
                    <Text style={[styles.filterChipText, active && styles.filterChipTextActive]}>
                      {country}
                    </Text>
                  </Pressable>
                );
              })}
            </View>
          </View>
        </ScrollView>
      </View>
    );
  }

  function renderMainApp() {
    if (openedOffer) return renderOfferDetail();
    if (openedMoodboard) return renderMoodboardDetail();

    return (
      <View style={styles.mainShell}>
        <View style={styles.mainTopBar}>
          <Text style={styles.brand}>StyleMatch</Text>
          <Text style={styles.bodySoft}>Prototype (gray placeholders only)</Text>
          <Text style={styles.bodySoft}>{BUILD_MARKER}</Text>
        </View>

        {activeTab === "home" && renderHome()}
        {activeTab === "moodboards" && renderMoodboards()}
        {activeTab === "archive" && renderArchive()}

        <View style={styles.tabBar}>
          <Pressable
            style={[styles.tabBtn, activeTab === "home" && styles.tabBtnActive]}
            onPress={() => setActiveTab("home")}
          >
            <Text style={[styles.tabBtnText, activeTab === "home" && styles.tabBtnTextActive]}>
              Home
            </Text>
          </Pressable>
          <Pressable
            style={[styles.tabBtn, activeTab === "moodboards" && styles.tabBtnActive]}
            onPress={() => {
              setOpenedMoodboardId(null);
              setActiveTab("moodboards");
            }}
          >
            <Text
              style={[styles.tabBtnText, activeTab === "moodboards" && styles.tabBtnTextActive]}
            >
              Moodboards
            </Text>
          </Pressable>
          <Pressable
            style={[styles.tabBtn, activeTab === "archive" && styles.tabBtnActive]}
            onPress={() => setActiveTab("archive")}
          >
            <Text style={[styles.tabBtnText, activeTab === "archive" && styles.tabBtnTextActive]}>
              Archive
            </Text>
          </Pressable>
        </View>
      </View>
    );
  }

  function renderFlow() {
    if (flowStage === "intro") return renderIntro();
    if (flowStage === "connect") return renderConnect();
    if (flowStage === "boards") return renderBoardsSelection();
    if (flowStage === "setup") return renderSetup();
    if (flowStage === "analyzing") return renderAnalyzing();
    return renderMainApp();
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <StatusBar style="dark" />
      <View style={styles.page}>{renderFlow()}</View>

      <Pressable style={styles.restartPill} onPress={resetEverything}>
        <Text style={styles.restartPillText}>Restart Flow</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: PALETTE.bg,
  },
  page: {
    flex: 1,
    paddingHorizontal: 12,
    paddingTop: 8,
    paddingBottom: 64,
  },
  flowCard: {
    flex: 1,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: PALETTE.border,
    backgroundColor: PALETTE.surface,
    padding: 16,
    gap: 12,
  },
  heroTitle: {
    fontSize: 32,
    fontWeight: "800",
    color: PALETTE.text,
    letterSpacing: -0.8,
  },
  heroSubtitle: {
    fontSize: 14,
    color: PALETTE.textSoft,
    fontWeight: "600",
    marginTop: -4,
  },
  bodyText: {
    fontSize: 16,
    lineHeight: 22,
    color: PALETTE.text,
  },
  bodySoft: {
    fontSize: 13,
    color: PALETTE.textSoft,
    fontWeight: "500",
  },
  dotsRow: {
    flexDirection: "row",
    gap: 8,
  },
  dot: {
    width: 9,
    height: 9,
    borderRadius: 9,
  },
  dotActive: {
    backgroundColor: PALETTE.accent,
  },
  dotInactive: {
    backgroundColor: PALETTE.border,
  },
  primaryButton: {
    backgroundColor: PALETTE.accent,
    borderRadius: 14,
    height: 48,
    alignItems: "center",
    justifyContent: "center",
    marginTop: "auto",
  },
  primaryButtonText: {
    color: PALETTE.accentText,
    fontWeight: "700",
    fontSize: 15,
  },
  connectCard: {
    backgroundColor: "#F2F2F2",
    borderRadius: 16,
    padding: 12,
    gap: 10,
  },
  connectAvatar: {
    width: 52,
    height: 52,
    borderRadius: 26,
    backgroundColor: PALETTE.placeholder,
  },
  searchInput: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    backgroundColor: "#F4F4F4",
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 10,
    color: PALETTE.text,
    fontSize: 15,
  },
  boardListItem: {
    flexDirection: "row",
    alignItems: "center",
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 14,
    backgroundColor: PALETTE.surface,
    padding: 8,
    marginBottom: 8,
    gap: 10,
  },
  boardListThumb: {
    width: 62,
    height: 62,
    borderRadius: 10,
    backgroundColor: PALETTE.placeholder,
  },
  tagPill: {
    paddingHorizontal: 10,
    height: 32,
    borderRadius: 16,
    backgroundColor: PALETTE.chip,
    alignItems: "center",
    justifyContent: "center",
  },
  tagPillActive: {
    backgroundColor: PALETTE.accent,
  },
  tagPillText: {
    color: PALETTE.textSoft,
    fontWeight: "700",
    fontSize: 12,
  },
  tagPillTextActive: {
    color: PALETTE.accentText,
  },
  inputGroup: {
    gap: 8,
  },
  fieldLabel: {
    fontSize: 12,
    fontWeight: "700",
    letterSpacing: 0.7,
    textTransform: "uppercase",
    color: PALETTE.textSoft,
    marginTop: 2,
  },
  rangeCard: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 14,
    backgroundColor: "#F4F4F4",
    padding: 10,
    gap: 10,
  },
  rangeTrackBase: {
    height: 8,
    backgroundColor: PALETTE.border,
    borderRadius: 8,
    overflow: "hidden",
  },
  rangeTrackActive: {
    position: "absolute",
    top: 0,
    bottom: 0,
    backgroundColor: PALETTE.accent,
  },
  inlineButtons: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  smallBtn: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    backgroundColor: PALETTE.surface,
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 8,
  },
  smallBtnText: {
    color: PALETTE.text,
    fontWeight: "600",
    fontSize: 12,
  },
  smallBtnActive: {
    backgroundColor: PALETTE.chipActive,
    borderColor: PALETTE.chipActive,
  },
  smallBtnTextActive: {
    color: PALETTE.chipActiveText,
  },
  progressCard: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 16,
    backgroundColor: "#F4F4F4",
    padding: 12,
    gap: 8,
  },
  progressBar: {
    height: 9,
    borderRadius: 9,
    backgroundColor: PALETTE.border,
    overflow: "hidden",
  },
  progressBarFill: {
    width: "100%",
    height: 9,
    borderRadius: 9,
    backgroundColor: PALETTE.accent,
  },
  mainShell: {
    flex: 1,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: PALETTE.border,
    backgroundColor: PALETTE.surface,
    overflow: "hidden",
  },
  mainTopBar: {
    paddingHorizontal: 14,
    paddingTop: 14,
    paddingBottom: 10,
    borderBottomWidth: 1,
    borderBottomColor: PALETTE.border,
  },
  brand: {
    fontSize: 26,
    fontWeight: "800",
    color: PALETTE.text,
    letterSpacing: -0.4,
  },
  tabBody: {
    flex: 1,
    paddingHorizontal: 12,
    paddingTop: 10,
    gap: 10,
  },
  headerRow: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: "800",
    color: PALETTE.text,
    letterSpacing: -0.4,
  },
  filterChip: {
    marginRight: 8,
    borderRadius: 999,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: PALETTE.chip,
  },
  filterChipActive: {
    backgroundColor: PALETTE.chipActive,
  },
  filterChipText: {
    color: PALETTE.text,
    fontSize: 13,
    fontWeight: "700",
  },
  filterChipTextActive: {
    color: PALETTE.chipActiveText,
  },
  pinCard: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 16,
    backgroundColor: PALETTE.surface,
    overflow: "hidden",
  },
  pinImage: {
    width: "100%",
    backgroundColor: PALETTE.placeholder,
  },
  pinTextWrap: {
    padding: 10,
    gap: 2,
  },
  cardTitle: {
    fontSize: 14,
    fontWeight: "700",
    color: PALETTE.text,
  },
  cardPrice: {
    fontSize: 13,
    fontWeight: "800",
    color: PALETTE.text,
    marginTop: 4,
  },
  emptyStateCard: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 14,
    backgroundColor: "#F4F4F4",
    padding: 12,
    gap: 4,
  },
  archiveRow: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 14,
    backgroundColor: PALETTE.surface,
    padding: 8,
    flexDirection: "row",
    gap: 10,
    alignItems: "center",
  },
  archiveThumb: {
    width: 56,
    height: 56,
    borderRadius: 10,
    backgroundColor: PALETTE.placeholder,
  },
  detailScreen: {
    flex: 1,
    borderRadius: 24,
    borderWidth: 1,
    borderColor: PALETTE.border,
    backgroundColor: PALETTE.surface,
    padding: 14,
    gap: 10,
  },
  backBtn: {
    alignSelf: "flex-start",
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 7,
    backgroundColor: "#F4F4F4",
  },
  backBtnText: {
    fontSize: 12,
    fontWeight: "700",
    color: PALETTE.text,
  },
  boardPage: {
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 14,
    backgroundColor: "#F7F7F7",
    padding: 10,
    gap: 8,
  },
  pageTitle: {
    fontSize: 18,
    fontWeight: "800",
    color: PALETTE.text,
  },
  wrapRow: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 8,
  },
  customRow: {
    flexDirection: "row",
    alignItems: "center",
    gap: 8,
    marginTop: 2,
  },
  addBtn: {
    backgroundColor: PALETTE.accent,
    borderRadius: 12,
    paddingHorizontal: 12,
    paddingVertical: 11,
  },
  addBtnText: {
    color: PALETTE.accentText,
    fontWeight: "700",
    fontSize: 12,
  },
  tabBar: {
    borderTopWidth: 1,
    borderTopColor: PALETTE.border,
    padding: 10,
    flexDirection: "row",
    gap: 8,
    backgroundColor: PALETTE.surface,
  },
  tabBtn: {
    flex: 1,
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 12,
    backgroundColor: "#F4F4F4",
    alignItems: "center",
    justifyContent: "center",
    paddingVertical: 10,
  },
  tabBtnActive: {
    backgroundColor: PALETTE.chipActive,
    borderColor: PALETTE.chipActive,
  },
  tabBtnText: {
    color: PALETTE.text,
    fontWeight: "700",
    fontSize: 13,
  },
  tabBtnTextActive: {
    color: PALETTE.chipActiveText,
  },
  restartPill: {
    position: "absolute",
    right: 12,
    bottom: 16,
    borderWidth: 1,
    borderColor: PALETTE.border,
    borderRadius: 999,
    backgroundColor: PALETTE.surface,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  restartPillText: {
    color: PALETTE.textSoft,
    fontSize: 12,
    fontWeight: "700",
  },
});

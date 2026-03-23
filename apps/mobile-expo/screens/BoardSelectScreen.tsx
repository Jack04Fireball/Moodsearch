import { useEffect, useState } from "react";
import {
  ActivityIndicator,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from "react-native";
import type { PinterestBoard } from "@stylematch/shared-types";
import { API_BASE_URL } from "../src/config";

type Props = {
  palette: Record<string, string>;
  token: string;
  onDone: (selectedBoards: PinterestBoard[]) => void;
};

export default function BoardSelectScreen({ palette, token, onDone }: Props) {
  const [boards, setBoards] = useState<PinterestBoard[]>([]);
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    fetchBoards();
  }, []);

  async function fetchBoards() {
    setErrorMessage(null);
    setLoading(true);
    try {
      const response = await fetch(`${API_BASE_URL}/v1/pinterest/boards`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!response.ok) {
        const text = await response.text();
        throw new Error(text || `HTTP ${response.status}`);
      }
      const data = await response.json();
      setBoards(data.boards ?? []);
    } catch (error) {
      console.error("Failed to fetch boards:", error);
      setErrorMessage(
        "Pinterest-Boards konnten nicht geladen werden. Bitte Pinterest erneut verbinden."
      );
    } finally {
      setLoading(false);
    }
  }

  function toggleBoard(boardId: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(boardId)) {
        next.delete(boardId);
      } else {
        next.add(boardId);
      }
      return next;
    });
  }

  function handleConfirm() {
    const selectedBoards = boards.filter((b) => selected.has(b.id));
    onDone(selectedBoards);
  }

  if (loading) {
    return (
      <View style={[styles.container, { backgroundColor: palette.bg }]}>
        <ActivityIndicator size="large" />
        <Text style={[styles.loadingText, { color: palette.textSoft }]}>
          Boards werden geladen…
        </Text>
      </View>
    );
  }

  return (
    <View style={[styles.container, { backgroundColor: palette.bg }]}>
      <View style={styles.header}>
        <Text style={[styles.title, { color: palette.text }]}>
          Boards auswählen
        </Text>
        <Text style={[styles.subtitle, { color: palette.textSoft }]}>
          Tippe auf die Boards, die deinen Style definieren.
        </Text>
      </View>

      {errorMessage ? (
        <View
          style={[
            styles.errorCard,
            { backgroundColor: palette.card, borderColor: palette.border },
          ]}
        >
          <Text style={[styles.errorText, { color: palette.textSoft }]}>
            {errorMessage}
          </Text>
          <Pressable
            style={[styles.retryBtn, { backgroundColor: palette.primary }]}
            onPress={fetchBoards}
          >
            <Text style={[styles.retryBtnText, { color: palette.primaryText }]}>
              Erneut versuchen
            </Text>
          </Pressable>
        </View>
      ) : null}

      <ScrollView
        contentContainerStyle={styles.grid}
        showsVerticalScrollIndicator={false}
      >
        {boards.map((board) => {
          const isSelected = selected.has(board.id);
          return (
            <Pressable
              key={board.id}
              style={[
                styles.boardCard,
                {
                  backgroundColor: palette.card,
                  borderColor: isSelected ? palette.primary : palette.border,
                  borderWidth: isSelected ? 2 : 1,
                },
              ]}
              onPress={() => toggleBoard(board.id)}
            >
              {board.imageUrl ? (
                <Image
                  source={{ uri: board.imageUrl }}
                  style={styles.boardImage}
                />
              ) : (
                <View
                  style={[
                    styles.boardImage,
                    { backgroundColor: palette.cardSoft },
                  ]}
                />
              )}
              <View style={styles.boardInfo}>
                <Text
                  style={[styles.boardName, { color: palette.text }]}
                  numberOfLines={1}
                >
                  {board.name}
                </Text>
                <Text style={[styles.boardPins, { color: palette.textSoft }]}>
                  {board.pinCount} Pins
                </Text>
              </View>
              {isSelected && (
                <View
                  style={[
                    styles.checkmark,
                    { backgroundColor: palette.primary },
                  ]}
                >
                  <Text style={{ color: palette.primaryText, fontWeight: "800" }}>
                    ✓
                  </Text>
                </View>
              )}
            </Pressable>
          );
        })}
      </ScrollView>

      <Pressable
        style={[
          styles.confirmBtn,
          { backgroundColor: palette.primary },
          selected.size === 0 && styles.disabledBtn,
        ]}
        disabled={selected.size === 0}
        onPress={handleConfirm}
      >
        <Text style={[styles.confirmBtnText, { color: palette.primaryText }]}>
          {selected.size > 0
            ? `${selected.size} Board${selected.size > 1 ? "s" : ""} verknüpfen`
            : "Mindestens 1 Board wählen"}
        </Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    paddingTop: 60,
    paddingHorizontal: 16,
  },
  header: {
    marginBottom: 20,
    gap: 4,
  },
  title: {
    fontSize: 28,
    fontWeight: "800",
    letterSpacing: -0.5,
  },
  subtitle: {
    fontSize: 15,
    fontWeight: "500",
  },
  errorCard: {
    borderRadius: 14,
    borderWidth: 1,
    padding: 12,
    marginBottom: 12,
    gap: 10,
  },
  errorText: {
    fontSize: 14,
    fontWeight: "500",
  },
  retryBtn: {
    alignSelf: "flex-start",
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  retryBtnText: {
    fontSize: 13,
    fontWeight: "700",
  },
  loadingText: {
    marginTop: 12,
    fontSize: 15,
    fontWeight: "500",
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    gap: 12,
    paddingBottom: 100,
  },
  boardCard: {
    width: "47%",
    borderRadius: 16,
    overflow: "hidden",
  },
  boardImage: {
    width: "100%",
    height: 120,
  },
  boardInfo: {
    padding: 10,
    gap: 2,
  },
  boardName: {
    fontSize: 14,
    fontWeight: "700",
  },
  boardPins: {
    fontSize: 12,
    fontWeight: "500",
  },
  checkmark: {
    position: "absolute",
    top: 8,
    right: 8,
    width: 28,
    height: 28,
    borderRadius: 14,
    alignItems: "center",
    justifyContent: "center",
  },
  confirmBtn: {
    position: "absolute",
    bottom: 40,
    left: 16,
    right: 16,
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: "center",
  },
  disabledBtn: {
    opacity: 0.4,
  },
  confirmBtnText: {
    fontSize: 16,
    fontWeight: "700",
  },
});

import * as WebBrowser from "expo-web-browser";
import { Pressable, StyleSheet, Text, View } from "react-native";
import { API_BASE_URL } from "../src/config";

type Props = {
  palette: Record<string, string>;
  onLogin: (params: {
    token: string;
    userId: string;
    username: string;
    profileImage?: string;
  }) => void;
};

export default function LoginScreen({ palette, onLogin }: Props) {
  async function handlePinterestLogin() {
    const redirectUri = "stylematch://auth";

    const result = await WebBrowser.openAuthSessionAsync(
      `${API_BASE_URL}/v1/auth/pinterest?redirect=${encodeURIComponent(redirectUri)}`,
      redirectUri
    );

    if (result.type === "success" && result.url) {
      const url = new URL(result.url);
      const token = url.searchParams.get("token");
      const userId = url.searchParams.get("userId");
      const username = url.searchParams.get("username");
      const profileImage = url.searchParams.get("profileImage") ?? undefined;

      if (token && userId && username) {
        onLogin({ token, userId, username, profileImage });
      }
    }
  }

  return (
    <View style={[styles.container, { backgroundColor: palette.bg }]}>
      <View style={styles.content}>
        <Text style={[styles.logo, { color: palette.text }]}>StyleMatch</Text>
        <Text style={[styles.tagline, { color: palette.textSoft }]}>
          Dein Style. Automatisch gefunden.
        </Text>

        <View style={styles.buttonGroup}>
          <Pressable
            style={[styles.loginBtn, { backgroundColor: palette.primary }]}
            onPress={handlePinterestLogin}
          >
            <Text style={[styles.loginBtnText, { color: palette.primaryText }]}>
              Mit Pinterest verbinden
            </Text>
          </Pressable>

          <Pressable
            style={[
              styles.loginBtn,
              {
                backgroundColor: "transparent",
                borderWidth: 1,
                borderColor: palette.border,
              },
            ]}
            onPress={() =>
              onLogin({
                token: "__demo__",
                userId: "demo_user",
                username: "Demo",
              })
            }
          >
            <Text style={[styles.loginBtnText, { color: palette.text }]}>
              Ohne Account testen
            </Text>
          </Pressable>
        </View>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    paddingHorizontal: 32,
  },
  content: {
    width: "100%",
    alignItems: "center",
    gap: 16,
  },
  logo: {
    fontSize: 42,
    fontWeight: "800",
    letterSpacing: -1,
  },
  tagline: {
    fontSize: 16,
    fontWeight: "500",
    marginBottom: 32,
  },
  buttonGroup: {
    width: "100%",
    gap: 12,
  },
  loginBtn: {
    width: "100%",
    paddingVertical: 16,
    borderRadius: 14,
    alignItems: "center",
  },
  loginBtnText: {
    fontSize: 16,
    fontWeight: "700",
  },
});

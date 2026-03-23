import { randomUUID } from "node:crypto";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { createStyleProfile, type ImageDescriptor } from "@stylematch/ai-core";
import { buildLocalizedQuery, scoreProduct } from "@stylematch/search-core";
import type {
  AuthResponse,
  DesignerLevel,
  FeedbackEvent,
  PinterestBoard,
  PinterestPin,
  PlatformType,
  ProductCondition,
  ProductResult,
  SearchPreferences,
  StyleProfile
} from "@stylematch/shared-types";

type CatalogItem = {
  id: string;
  title: string;
  description: string;
  brand: string;
  price: number;
  currency: string;
  condition: ProductCondition;
  platformType: PlatformType;
  designerLevel: DesignerLevel;
  quality: "low" | "medium" | "high";
  country: string;
  sizes: string[];
  signals: string[];
  imageUrl: string;
  productUrl: string;
};

const PORT = Number(process.env.PORT ?? 4000);

const DEMO_USER = {
  id: "pinterest_user_01",
  username: "NoahStyle",
  profileImage: "https://picsum.photos/seed/noahstyle/200/200"
};

const sessions = new Map<string, typeof DEMO_USER>();
const profilesByBoard = new Map<string, StyleProfile>();
const boardPreferences = new Map<string, SearchPreferences>();
const feedbackEvents: FeedbackEvent[] = [];

const boards: PinterestBoard[] = [
  {
    id: "board_minimal",
    name: "Minimal Outfits",
    description: "Clean silhouettes, monochrome looks, tailored cuts",
    imageUrl: "https://picsum.photos/seed/minimal/800/1200?grayscale",
    pinCount: 58,
    privacy: "PROTECTED"
  },
  {
    id: "board_punk",
    name: "Punk Editorial",
    description: "Leather, hardware, high contrast statements",
    imageUrl: "https://picsum.photos/seed/punk/800/1200?grayscale",
    pinCount: 43,
    privacy: "PROTECTED"
  },
  {
    id: "board_street",
    name: "Streetwear Layers",
    description: "Oversized layers and utility shapes",
    imageUrl: "https://picsum.photos/seed/street/800/1200?grayscale",
    pinCount: 66,
    privacy: "PROTECTED"
  }
];

const pinsByBoard = new Map<string, PinterestPin[]>([
  [
    "board_minimal",
    [
      {
        id: "pin_m_1",
        title: "Black tailored blazer look",
        description: "Minimal monochrome tailoring in wool with clean lines",
        imageUrl: "https://picsum.photos/seed/pin_m_1/1200/1800?grayscale",
        dominantColor: "black"
      },
      {
        id: "pin_m_2",
        title: "Wide-leg trousers in grey wool",
        description: "Editorial minimal styling, soft neutral palette",
        imageUrl: "https://picsum.photos/seed/pin_m_2/1200/1800?grayscale",
        dominantColor: "gray"
      },
      {
        id: "pin_m_3",
        title: "Cropped knit with straight denim",
        description: "Simple silhouette with modern proportions",
        imageUrl: "https://picsum.photos/seed/pin_m_3/1200/1800?grayscale",
        dominantColor: "charcoal"
      }
    ]
  ],
  [
    "board_punk",
    [
      {
        id: "pin_p_1",
        title: "Red-black punk leather jacket",
        description: "Grunge texture, hardware details, distressed finish",
        imageUrl: "https://picsum.photos/seed/pin_p_1/1200/1800?grayscale",
        dominantColor: "black"
      },
      {
        id: "pin_p_2",
        title: "Heavy boots and metal accents",
        description: "Dark editorial outfit with rebellious vibe",
        imageUrl: "https://picsum.photos/seed/pin_p_2/1200/1800?grayscale",
        dominantColor: "black"
      },
      {
        id: "pin_p_3",
        title: "Oversized coat with red statement",
        description: "High contrast fashion poster style",
        imageUrl: "https://picsum.photos/seed/pin_p_3/1200/1800?grayscale",
        dominantColor: "red"
      }
    ]
  ],
  [
    "board_street",
    [
      {
        id: "pin_s_1",
        title: "Utility cargo and oversized hoodie",
        description: "Streetwear layering and functional details",
        imageUrl: "https://picsum.photos/seed/pin_s_1/1200/1800?grayscale",
        dominantColor: "olive"
      },
      {
        id: "pin_s_2",
        title: "Technical jacket and relaxed pants",
        description: "Urban look with clean sportswear lines",
        imageUrl: "https://picsum.photos/seed/pin_s_2/1200/1800?grayscale",
        dominantColor: "gray"
      },
      {
        id: "pin_s_3",
        title: "Layered neutral street set",
        description: "Minimal street silhouette with wide fit",
        imageUrl: "https://picsum.photos/seed/pin_s_3/1200/1800?grayscale",
        dominantColor: "beige"
      }
    ]
  ]
]);

const catalog: CatalogItem[] = [
  {
    id: "sku_001",
    title: "Tailored Wool Blazer",
    description: "Sharp shoulder line and clean fit for editorial looks",
    brand: "COS",
    price: 310,
    currency: "CHF",
    condition: "new",
    platformType: "retail",
    designerLevel: "premium",
    quality: "high",
    country: "CH",
    sizes: ["S", "M", "L"],
    signals: ["tailored", "minimal", "wool", "black"],
    imageUrl: "https://picsum.photos/seed/sku_001/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_001"
  },
  {
    id: "sku_002",
    title: "Distressed Leather Jacket",
    description: "Vintage-inspired leather with punk attitude",
    brand: "AllSaints",
    price: 590,
    currency: "CHF",
    condition: "new",
    platformType: "retail",
    designerLevel: "premium",
    quality: "high",
    country: "IT",
    sizes: ["M", "L"],
    signals: ["punk", "grunge", "leather", "black", "oversized"],
    imageUrl: "https://picsum.photos/seed/sku_002/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_002"
  },
  {
    id: "sku_003",
    title: "Wide-Leg Wool Trousers",
    description: "Relaxed volume with formal wool texture",
    brand: "ARKET",
    price: 180,
    currency: "CHF",
    condition: "new",
    platformType: "retail",
    designerLevel: "mass",
    quality: "medium",
    country: "SE",
    sizes: ["XS", "S", "M", "L"],
    signals: ["wide-leg", "wool", "minimal", "gray"],
    imageUrl: "https://picsum.photos/seed/sku_003/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_003"
  },
  {
    id: "sku_004",
    title: "Combat Lace Boots",
    description: "Durable sole with metal eyelets and heavy profile",
    brand: "Dr. Martens",
    price: 240,
    currency: "CHF",
    condition: "new",
    platformType: "retail",
    designerLevel: "premium",
    quality: "high",
    country: "GB",
    sizes: ["40", "41", "42", "43", "44"],
    signals: ["punk", "grunge", "black", "hardware"],
    imageUrl: "https://picsum.photos/seed/sku_004/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_004"
  },
  {
    id: "sku_005",
    title: "Oversized Utility Hoodie",
    description: "Street fit with technical pocket and washed surface",
    brand: "Carhartt WIP",
    price: 130,
    currency: "CHF",
    condition: "new",
    platformType: "retail",
    designerLevel: "mass",
    quality: "medium",
    country: "DE",
    sizes: ["S", "M", "L", "XL"],
    signals: ["streetwear", "oversized", "utility", "gray"],
    imageUrl: "https://picsum.photos/seed/sku_005/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_005"
  },
  {
    id: "sku_006",
    title: "Vintage Red Statement Tee",
    description: "Graphic typography with distressed punk print",
    brand: "Balenciaga",
    price: 480,
    currency: "CHF",
    condition: "like_new",
    platformType: "resale",
    designerLevel: "luxury",
    quality: "high",
    country: "FR",
    sizes: ["M", "L"],
    signals: ["punk", "red", "editorial", "grunge"],
    imageUrl: "https://picsum.photos/seed/sku_006/1000/1400?grayscale",
    productUrl: "https://example.com/products/sku_006"
  }
];

const materialWords = new Set(["wool", "leather", "denim", "cotton", "knit", "satin"]);
const silhouetteWords = new Set([
  "oversized",
  "tailored",
  "cropped",
  "wide-leg",
  "wide",
  "straight",
  "relaxed"
]);
const vibeWords = new Set(["minimal", "editorial", "punk", "grunge", "streetwear", "utility"]);
const colorWords = new Set([
  "black",
  "gray",
  "grey",
  "charcoal",
  "red",
  "white",
  "olive",
  "beige",
  "silver"
]);

const defaultPreferences = (userId: string): SearchPreferences => ({
  userId,
  minPrice: 0,
  maxPrice: 2500,
  currency: "CHF",
  designerLevel: ["mass", "premium", "luxury"],
  platformTypes: ["retail", "marketplace", "resale"],
  conditions: ["new", "like_new", "good", "fair"],
  sizes: [],
  shippingCountries: []
});

const withCors = (res: ServerResponse): void => {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.setHeader("Access-Control-Allow-Methods", "GET,POST,PUT,OPTIONS");
};

const sendJson = (res: ServerResponse, statusCode: number, payload: unknown): void => {
  withCors(res);
  res.statusCode = statusCode;
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.end(JSON.stringify(payload));
};

const sendError = (res: ServerResponse, statusCode: number, message: string): void => {
  sendJson(res, statusCode, { error: message });
};

const parseJsonBody = async (req: IncomingMessage): Promise<Record<string, unknown>> => {
  if (!req.method || !["POST", "PUT", "PATCH"].includes(req.method)) return {};
  const chunks: Buffer[] = [];

  for await (const chunk of req) {
    chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
  }

  if (chunks.length === 0) return {};
  const raw = Buffer.concat(chunks).toString("utf-8").trim();
  if (!raw) return {};

  try {
    return JSON.parse(raw) as Record<string, unknown>;
  } catch {
    throw new Error("Invalid JSON body.");
  }
};

const toTokens = (input: string): string[] =>
  input
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, " ")
    .split(/\s+/)
    .map((v) => v.trim())
    .filter(Boolean);

const toImageDescriptor = (pin: PinterestPin): ImageDescriptor => {
  const source = `${pin.title ?? ""} ${pin.description ?? ""} ${pin.dominantColor ?? ""}`.trim();
  const tokens = toTokens(source);
  const dominantColors = [...new Set(tokens.filter((token) => colorWords.has(token)))];
  const materials = [...new Set(tokens.filter((token) => materialWords.has(token)))];
  const silhouettes = [...new Set(tokens.filter((token) => silhouetteWords.has(token)))];
  const vibes = [...new Set(tokens.filter((token) => vibeWords.has(token)))];

  if (dominantColors.length === 0 && pin.dominantColor) dominantColors.push(pin.dominantColor.toLowerCase());

  return {
    imageId: pin.id,
    tags: tokens,
    dominantColors,
    materials,
    silhouettes,
    vibes
  };
};

const ensureAuthUser = (req: IncomingMessage): typeof DEMO_USER | null => {
  const header = req.headers.authorization;
  if (!header || !header.startsWith("Bearer ")) return null;
  const token = header.slice("Bearer ".length).trim();
  if (token === "__demo__") return DEMO_USER;
  return sessions.get(token) ?? null;
};

const normalizePreferences = (params: {
  userId: string;
  current?: SearchPreferences;
  update?: Partial<SearchPreferences>;
}): SearchPreferences => {
  const base = params.current ?? defaultPreferences(params.userId);
  const incoming = params.update ?? {};

  return {
    userId: params.userId,
    minPrice:
      typeof incoming.minPrice === "number"
        ? incoming.minPrice
        : typeof base.minPrice === "number"
          ? base.minPrice
          : 0,
    maxPrice:
      typeof incoming.maxPrice === "number"
        ? incoming.maxPrice
        : typeof base.maxPrice === "number"
          ? base.maxPrice
          : 3000,
    currency: typeof incoming.currency === "string" ? incoming.currency : base.currency,
    designerLevel:
      incoming.designerLevel && incoming.designerLevel.length > 0
        ? incoming.designerLevel
        : base.designerLevel,
    platformTypes:
      incoming.platformTypes && incoming.platformTypes.length > 0
        ? incoming.platformTypes
        : base.platformTypes,
    conditions:
      incoming.conditions && incoming.conditions.length > 0 ? incoming.conditions : base.conditions,
    sizes: incoming.sizes && incoming.sizes.length > 0 ? incoming.sizes : base.sizes,
    shippingCountries:
      incoming.shippingCountries && incoming.shippingCountries.length > 0
        ? incoming.shippingCountries
        : base.shippingCountries
  };
};

const analyzeBoard = (boardId: string, userId: string): StyleProfile => {
  const board = boards.find((entry) => entry.id === boardId);
  const pins = pinsByBoard.get(boardId) ?? [];
  const images = pins.map(toImageDescriptor);

  const profile = createStyleProfile({
    profileId: `profile_${boardId}`,
    userId,
    label: board?.name ?? boardId,
    images
  });

  profilesByBoard.set(boardId, profile);
  return profile;
};

const runSearch = (params: {
  boardId: string;
  locale: string;
  preferences: SearchPreferences;
  profile: StyleProfile;
}): {
  requestId: string;
  total: number;
  products: ProductResult[];
  query: string[];
} => {
  const profileSignalValues = new Set(params.profile.signals.map((signal) => signal.value.toLowerCase()));
  const localized = buildLocalizedQuery(params.profile, params.locale);

  const eligibleProducts = catalog.filter((item) => {
    if (item.currency !== params.preferences.currency) return false;
    if (typeof params.preferences.minPrice === "number" && item.price < params.preferences.minPrice) {
      return false;
    }
    if (typeof params.preferences.maxPrice === "number" && item.price > params.preferences.maxPrice) {
      return false;
    }
    if (!params.preferences.platformTypes.includes(item.platformType)) return false;
    if (!params.preferences.conditions.includes(item.condition)) return false;
    if (params.preferences.sizes.length > 0) {
      const hasSize = item.sizes.some((size) => params.preferences.sizes.includes(size));
      if (!hasSize) return false;
    }
    if (params.preferences.shippingCountries.length > 0) {
      const ships = params.preferences.shippingCountries.includes(item.country);
      if (!ships) return false;
    }
    return true;
  });

  const rankedProducts: ProductResult[] = eligibleProducts
    .map((item) => {
      const matchedSignals = item.signals.filter((signal) => profileSignalValues.has(signal.toLowerCase()));
      const baseScore = scoreProduct(
        {
          price: item.price,
          condition: item.condition,
          matchedSignals
        },
        params.profile,
        params.preferences
      );

      const designerBoost = params.preferences.designerLevel.includes(item.designerLevel) ? 0.08 : 0;
      const qualityBoost = item.quality === "high" ? 0.08 : item.quality === "medium" ? 0.04 : 0;
      const countryBoost =
        params.preferences.shippingCountries.length === 0 ||
        params.preferences.shippingCountries.includes(item.country)
          ? 0.04
          : 0;

      const matchScore = Number(Math.min(0.99, baseScore + designerBoost + qualityBoost + countryBoost).toFixed(3));

      return {
        id: item.id,
        platformSourceId: `${item.platformType}:${item.brand.toLowerCase()}`,
        externalId: item.id,
        title: item.title,
        description: item.description,
        brand: item.brand,
        price: item.price,
        currency: item.currency,
        condition: item.condition,
        imageUrl: item.imageUrl,
        productUrl: item.productUrl,
        language: params.locale,
        inStock: true,
        matchScore,
        matchedSignals,
        createdAt: new Date().toISOString()
      } satisfies ProductResult;
    })
    .sort((a, b) => b.matchScore - a.matchScore);

  return {
    requestId: `req_${params.boardId}_${Date.now()}`,
    total: rankedProducts.length,
    products: rankedProducts,
    query: localized.terms
  };
};

const server = createServer(async (req, res) => {
  try {
    const requestUrl = new URL(req.url ?? "/", `http://${req.headers.host ?? "localhost"}`);
    const path = requestUrl.pathname;
    const method = req.method ?? "GET";

    if (method === "OPTIONS") {
      withCors(res);
      res.statusCode = 204;
      res.end();
      return;
    }

    if (method === "GET" && path === "/health") {
      sendJson(res, 200, {
        ok: true,
        service: "stylematch-backend",
        now: new Date().toISOString()
      });
      return;
    }

    if (method === "GET" && path === "/v1/auth/pinterest") {
      const redirect = requestUrl.searchParams.get("redirect");
      const token = `st_${randomUUID().replace(/-/g, "")}`;

      const authPayload: AuthResponse = {
        token,
        user: DEMO_USER
      };

      sessions.set(token, DEMO_USER);

      if (!redirect) {
        sendJson(res, 200, authPayload);
        return;
      }

      let callbackUrl: URL;
      try {
        callbackUrl = new URL(redirect);
      } catch {
        sendError(res, 400, "Invalid redirect URL.");
        return;
      }

      callbackUrl.searchParams.set("token", token);
      callbackUrl.searchParams.set("userId", DEMO_USER.id);
      callbackUrl.searchParams.set("username", DEMO_USER.username);
      callbackUrl.searchParams.set("profileImage", DEMO_USER.profileImage);

      withCors(res);
      res.statusCode = 302;
      res.setHeader("Location", callbackUrl.toString());
      res.end();
      return;
    }

    if (method === "GET" && path === "/v1/pinterest/boards") {
      const user = ensureAuthUser(req);
      if (!user) {
        sendError(res, 401, "Missing or invalid bearer token.");
        return;
      }
      sendJson(res, 200, { boards });
      return;
    }

    const boardPinsMatch = path.match(/^\/v1\/pinterest\/boards\/([^/]+)\/pins$/);
    if (method === "GET" && boardPinsMatch) {
      const user = ensureAuthUser(req);
      if (!user) {
        sendError(res, 401, "Missing or invalid bearer token.");
        return;
      }

      const boardId = decodeURIComponent(boardPinsMatch[1]);
      sendJson(res, 200, { boardId, pins: pinsByBoard.get(boardId) ?? [] });
      return;
    }

    const analyzeMatch = path.match(/^\/v1\/moodboards\/([^/]+)\/analyze$/);
    if (method === "POST" && analyzeMatch) {
      const user = ensureAuthUser(req) ?? DEMO_USER;
      const boardId = decodeURIComponent(analyzeMatch[1]);
      const profile = analyzeBoard(boardId, user.id);

      sendJson(res, 200, {
        boardId,
        profile,
        topSignals: profile.signals.slice(0, 12)
      });
      return;
    }

    const prefsMatch = path.match(/^\/v1\/moodboards\/([^/]+)\/preferences$/);
    if (prefsMatch) {
      const user = ensureAuthUser(req) ?? DEMO_USER;
      const boardId = decodeURIComponent(prefsMatch[1]);
      const current = boardPreferences.get(boardId) ?? defaultPreferences(user.id);

      if (method === "GET") {
        sendJson(res, 200, { boardId, preferences: current });
        return;
      }

      if (method === "PUT") {
        const payload = (await parseJsonBody(req)) as { preferences?: Partial<SearchPreferences> };
        const updated = normalizePreferences({
          userId: user.id,
          current,
          update: payload.preferences
        });
        boardPreferences.set(boardId, updated);
        sendJson(res, 200, { boardId, preferences: updated });
        return;
      }
    }

    const searchMatch = path.match(/^\/v1\/moodboards\/([^/]+)\/search$/);
    if (method === "POST" && searchMatch) {
      const user = ensureAuthUser(req) ?? DEMO_USER;
      const boardId = decodeURIComponent(searchMatch[1]);
      const payload = (await parseJsonBody(req)) as {
        locale?: string;
        preferences?: Partial<SearchPreferences>;
      };

      const existingProfile = profilesByBoard.get(boardId);
      const profile = existingProfile ?? analyzeBoard(boardId, user.id);

      const storedPreferences = boardPreferences.get(boardId);
      const mergedPreferences = normalizePreferences({
        userId: user.id,
        current: storedPreferences,
        update: payload.preferences
      });
      boardPreferences.set(boardId, mergedPreferences);

      const result = runSearch({
        boardId,
        locale: payload.locale ?? "en",
        preferences: mergedPreferences,
        profile
      });

      sendJson(res, 200, {
        boardId,
        profileId: profile.id,
        locale: payload.locale ?? "en",
        queryTerms: result.query,
        total: result.total,
        requestId: result.requestId,
        products: result.products
      });
      return;
    }

    if (method === "POST" && path === "/v1/feedback") {
      const user = ensureAuthUser(req) ?? DEMO_USER;
      const payload = (await parseJsonBody(req)) as Partial<FeedbackEvent>;

      if (!payload.productId || !payload.eventType) {
        sendError(res, 400, "productId and eventType are required.");
        return;
      }

      const event: FeedbackEvent = {
        id: payload.id ?? randomUUID(),
        userId: payload.userId ?? user.id,
        productId: payload.productId,
        eventType: payload.eventType,
        value: payload.value,
        createdAt: payload.createdAt ?? new Date().toISOString()
      };

      feedbackEvents.push(event);
      sendJson(res, 201, { stored: true, event });
      return;
    }

    sendError(res, 404, "Route not found.");
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error.";
    sendError(res, 500, message);
  }
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`[backend] stylematch-backend running on http://0.0.0.0:${PORT}`);
});

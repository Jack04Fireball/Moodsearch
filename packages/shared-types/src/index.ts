export type DesignerLevel = "mass" | "premium" | "luxury";
export type PlatformType = "retail" | "marketplace" | "resale";
export type ProductCondition = "new" | "like_new" | "good" | "fair";

export interface StyleSignal {
  category: "silhouette" | "color" | "material" | "pattern" | "vibe" | "era";
  value: string;
  weight: number;
  sourceImageId?: string;
}

export interface StyleProfile {
  id: string;
  userId: string;
  label: string;
  confidence: number;
  signals: StyleSignal[];
  excludedSignals: string[];
  createdAt: string;
  updatedAt: string;
}

export interface SearchPreferences {
  userId: string;
  minPrice?: number;
  maxPrice?: number;
  currency: string;
  designerLevel: DesignerLevel[];
  platformTypes: PlatformType[];
  conditions: ProductCondition[];
  sizes: string[];
  shippingCountries: string[];
}

export interface ProductResult {
  id: string;
  platformSourceId: string;
  externalId: string;
  title: string;
  description?: string;
  brand?: string;
  price: number;
  currency: string;
  condition: ProductCondition;
  imageUrl?: string;
  productUrl: string;
  language: string;
  inStock: boolean;
  matchScore: number;
  matchedSignals: string[];
  createdAt: string;
}

export interface FeedbackEvent {
  id: string;
  userId: string;
  productId: string;
  eventType:
    | "view"
    | "click"
    | "save"
    | "unsave"
    | "ignore"
    | "like"
    | "dislike"
    | "purchase_intent"
    | "filter_change";
  value?: string;
  createdAt: string;
}

export interface SearchRequest {
  userId: string;
  styleProfileId: string;
  locale: string;
  preferences: SearchPreferences;
}

export interface SearchResponse {
  requestId: string;
  total: number;
  products: ProductResult[];
}

// ── Pinterest Integration ──────────────────────────────────

export interface PinterestUser {
  id: string;
  username: string;
  profileImage?: string;
}

export interface PinterestBoard {
  id: string;
  name: string;
  description?: string;
  imageUrl?: string;
  pinCount: number;
  privacy: "PUBLIC" | "PROTECTED" | "SECRET";
}

export interface PinterestPin {
  id: string;
  title?: string;
  description?: string;
  imageUrl: string;
  dominantColor?: string;
  link?: string;
}

export interface AuthResponse {
  token: string;
  user: PinterestUser;
}

export interface BoardSelection {
  boardId: string;
  boardName: string;
  selected: boolean;
}

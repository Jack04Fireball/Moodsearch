import type { ProductResult, SearchPreferences, StyleProfile } from "@stylematch/shared-types";

export interface LocalizedQuery {
  locale: string;
  terms: string[];
}

const localeMap: Record<string, Record<string, string>> = {
  en: { blazer: "blazer", wool: "wool", black: "black", minimal: "minimalist" },
  de: { blazer: "blazer", wool: "wolle", black: "schwarz", minimal: "minimalistisch" },
  fr: { blazer: "blazer", wool: "laine", black: "noir", minimal: "minimaliste" }
};

export function buildLocalizedQuery(profile: StyleProfile, locale: string): LocalizedQuery {
  const dict = localeMap[locale] ?? localeMap.en;
  const top = profile.signals.slice(0, 8).map((s) => dict[s.value] ?? s.value);
  return { locale, terms: [...new Set(top)] };
}

export function scoreProduct(
  product: Pick<ProductResult, "price" | "condition" | "matchedSignals">,
  profile: StyleProfile,
  preferences: SearchPreferences
): number {
  const signalMatch = product.matchedSignals.length / Math.max(profile.signals.length, 1);
  const pricePenalty =
    preferences.maxPrice && product.price > preferences.maxPrice
      ? Math.min(0.5, (product.price - preferences.maxPrice) / preferences.maxPrice)
      : 0;
  const conditionBoost = product.condition === "new" || product.condition === "like_new" ? 0.1 : 0;
  return Number(Math.max(0, signalMatch + conditionBoost - pricePenalty).toFixed(3));
}

export type PriceRange = {
  min?: number;
  max?: number;
};

export type InteractionKind =
  | "like"
  | "dislike"
  | "save"
  | "archive"
  | "click"
  | "purchase"
  | "ignore";

export type MoodboardPin = {
  id: string;
  moodboardId?: string;
  title?: string;
  description?: string;
  designer?: string;
  brand?: string;
  colors?: string[];
  materials?: string[];
  silhouettes?: string[];
  patterns?: string[];
  vibes?: string[];
  priceHint?: number;
};

export type ProductCandidate = {
  id: string;
  title: string;
  moodboardId?: string;
  brand?: string;
  designer?: string;
  price?: number;
  currency?: string;
  colors?: string[];
  materials?: string[];
  silhouettes?: string[];
  patterns?: string[];
  vibes?: string[];
  source?: string;
  inStock?: boolean;
  available?: boolean;
};

export type MoodboardFocus = {
  preferredDesigners?: string[];
  preferredBrands?: string[];
  avoidedDesigners?: string[];
  avoidedBrands?: string[];
};

export type UserFocus = {
  preferredDesigners?: string[];
  preferredBrands?: string[];
  avoidedDesigners?: string[];
  avoidedBrands?: string[];
  moodboards?: Record<string, MoodboardFocus>;
};

export type SearchConstraints = {
  priceRange?: PriceRange;
  currencies?: string[];
  inStockOnly?: boolean;
  allowedSources?: string[];
};

export type InteractionSignal = {
  kind: InteractionKind;
  candidateId?: string;
  moodboardId?: string;
  brand?: string;
  designer?: string;
  price?: number;
  currency?: string;
};

export type PreferenceProfile = {
  preferredDesigners: Record<string, number>;
  preferredBrands: Record<string, number>;
  avoidedDesigners: Record<string, number>;
  avoidedBrands: Record<string, number>;
  preferredPrice?: PriceRange;
  lastUpdatedAt?: string;
};

export type StyleFingerprint = {
  tokens: Record<string, number>;
  colors: Record<string, number>;
  materials: Record<string, number>;
  silhouettes: Record<string, number>;
  patterns: Record<string, number>;
  vibes: Record<string, number>;
  designers: Record<string, number>;
  brands: Record<string, number>;
  priceHint?: PriceRange;
};

export type ScoreBreakdown = {
  style: number;
  focus: number;
  price: number;
  feedback: number;
  total: number;
  matchedTokens: string[];
  blockedByConstraint: boolean;
  reasons: string[];
};

export type RankedCandidate = {
  candidate: ProductCandidate;
  score: number;
  breakdown: ScoreBreakdown;
};

const FOCUS_BOOST_WEIGHT = 0.18;
const FOCUS_PENALTY_WEIGHT = -0.12;
const FEEDBACK_WEIGHT = 0.08;
const CLICK_WEIGHT = 0.03;
const SAVE_WEIGHT = 0.07;
const LIKE_WEIGHT = 0.1;
const PURCHASE_WEIGHT = 0.14;
const DISLIKE_WEIGHT = -0.1;
const IGNORE_WEIGHT = -0.05;

function normalizeToken(value: string | undefined): string | undefined {
  const token = value?.trim().toLowerCase();
  return token && token.length > 0 ? token : undefined;
}

function addTextTokens(bucket: Record<string, number>, value: string | undefined, weight = 1): void {
  const text = value?.trim().toLowerCase();
  if (!text) {
    return;
  }

  for (const token of text.split(/[^a-z0-9äöüß]+/i)) {
    addToken(bucket, token, weight);
  }
}

function tokenizeText(value: string | undefined): string[] {
  const text = value?.trim().toLowerCase();
  if (!text) {
    return [];
  }

  return text.split(/[^a-z0-9äöüß]+/i).filter((token) => token.length > 0);
}

function addToken(bucket: Record<string, number>, value: string | undefined, weight = 1): void {
  const token = normalizeToken(value);
  if (!token) {
    return;
  }
  bucket[token] = (bucket[token] ?? 0) + weight;
}

function addTokens(bucket: Record<string, number>, values: readonly (string | undefined)[] | undefined, weight = 1): void {
  if (!values) {
    return;
  }
  for (const value of values) {
    addToken(bucket, value, weight);
  }
}

function mergeUniqueTokens(...groups: Array<readonly (string | undefined)[] | undefined>): string[] {
  const seen = new Set<string>();
  const output: string[] = [];
  for (const group of groups) {
    if (!group) {
      continue;
    }
    for (const value of group) {
      const token = normalizeToken(value);
      if (!token || seen.has(token)) {
        continue;
      }
      seen.add(token);
      output.push(token);
    }
  }
  return output;
}

function sumValues(bucket: Record<string, number>): number {
  return Object.values(bucket).reduce((sum, value) => sum + value, 0);
}

function isInStock(candidate: ProductCandidate): boolean {
  return candidate.inStock !== false && candidate.available !== false;
}

function getMoodboardFocus(focus: UserFocus | undefined, moodboardId?: string): MoodboardFocus | undefined {
  if (!focus || !moodboardId) {
    return undefined;
  }
  return focus.moodboards?.[moodboardId];
}

function countTokenMatches(
  fingerprintBucket: Record<string, number>,
  candidateValues: readonly (string | undefined)[] | undefined,
): { score: number; matches: string[] } {
  if (!candidateValues || Object.keys(fingerprintBucket).length === 0) {
    return { score: 0, matches: [] };
  }

  let score = 0;
  const matches: string[] = [];
  const seen = new Set<string>();

  for (const value of candidateValues) {
    const token = normalizeToken(value);
    if (!token || seen.has(token)) {
      continue;
    }
    seen.add(token);
    const weight = fingerprintBucket[token];
    if (typeof weight === "number") {
      score += weight;
      matches.push(token);
    }
  }

  return { score, matches };
}

function totalFingerprintWeight(fingerprint: StyleFingerprint): number {
  return [
    sumValues(fingerprint.tokens),
    sumValues(fingerprint.colors),
    sumValues(fingerprint.materials),
    sumValues(fingerprint.silhouettes),
    sumValues(fingerprint.patterns),
    sumValues(fingerprint.vibes),
    sumValues(fingerprint.designers),
    sumValues(fingerprint.brands),
  ].reduce((sum, value) => sum + value, 0);
}

function clampScore(value: number): number {
  if (value > 1) {
    return 1;
  }
  if (value < -1) {
    return -1;
  }
  return value;
}

function scorePrice(candidate: ProductCandidate, constraints?: SearchConstraints, fingerprint?: StyleFingerprint): number {
  const price = candidate.price;
  if (typeof price !== "number") {
    return 0;
  }

  const priceRange = constraints?.priceRange ?? fingerprint?.priceHint;
  if (!priceRange) {
    return 0;
  }

  const min = priceRange.min;
  const max = priceRange.max;

  if (typeof min === "number" && price < min) {
    return -0.15;
  }
  if (typeof max === "number" && price > max) {
    const overshoot = max > 0 ? (price - max) / max : 1;
    return -Math.min(0.3, 0.08 + overshoot * 0.08);
  }

  return 0.08;
}

function constraintBlocks(candidate: ProductCandidate, constraints?: SearchConstraints): boolean {
  if (!constraints) {
    return false;
  }

  if (constraints.inStockOnly && !isInStock(candidate)) {
    return true;
  }

  if (constraints.currencies && constraints.currencies.length > 0) {
    const currency = normalizeToken(candidate.currency);
    if (!currency || !constraints.currencies.map(normalizeToken).includes(currency)) {
      return true;
    }
  }

  if (constraints.allowedSources && constraints.allowedSources.length > 0) {
    const source = normalizeToken(candidate.source);
    if (!source || !constraints.allowedSources.map(normalizeToken).includes(source)) {
      return true;
    }
  }

  if (constraints.priceRange && typeof candidate.price === "number") {
    const { min, max } = constraints.priceRange;
    if (typeof min === "number" && candidate.price < min) {
      return true;
    }
    if (typeof max === "number" && candidate.price > max) {
      return true;
    }
  }

  return false;
}

function resolveFocusSets(focus: UserFocus | undefined, moodboardId?: string) {
  const moodboardFocus = getMoodboardFocus(focus, moodboardId);

  return {
    preferredDesigners: mergeUniqueTokens(focus?.preferredDesigners, moodboardFocus?.preferredDesigners),
    preferredBrands: mergeUniqueTokens(focus?.preferredBrands, moodboardFocus?.preferredBrands),
    avoidedDesigners: mergeUniqueTokens(focus?.avoidedDesigners, moodboardFocus?.avoidedDesigners),
    avoidedBrands: mergeUniqueTokens(focus?.avoidedBrands, moodboardFocus?.avoidedBrands),
  };
}

export function extractStyleFingerprint(pins: MoodboardPin[]): StyleFingerprint {
  const fingerprint: StyleFingerprint = {
    tokens: {},
    colors: {},
    materials: {},
    silhouettes: {},
    patterns: {},
    vibes: {},
    designers: {},
    brands: {},
  };

  let priceMin: number | undefined;
  let priceMax: number | undefined;

  for (const pin of pins) {
    addTextTokens(fingerprint.tokens, pin.title, 1);
    addTextTokens(fingerprint.tokens, pin.description, 1);
    addToken(fingerprint.designers, pin.designer, 1);
    addToken(fingerprint.brands, pin.brand, 1);
    addTokens(fingerprint.colors, pin.colors, 1);
    addTokens(fingerprint.materials, pin.materials, 1);
    addTokens(fingerprint.silhouettes, pin.silhouettes, 1);
    addTokens(fingerprint.patterns, pin.patterns, 1);
    addTokens(fingerprint.vibes, pin.vibes, 1);

    if (typeof pin.priceHint === "number") {
      priceMin = typeof priceMin === "number" ? Math.min(priceMin, pin.priceHint) : pin.priceHint;
      priceMax = typeof priceMax === "number" ? Math.max(priceMax, pin.priceHint) : pin.priceHint;
    }
  }

  if (typeof priceMin === "number" || typeof priceMax === "number") {
    fingerprint.priceHint = {};
    if (typeof priceMin === "number") {
      fingerprint.priceHint.min = priceMin;
    }
    if (typeof priceMax === "number") {
      fingerprint.priceHint.max = priceMax;
    }
  }

  return fingerprint;
}

export function scoreCandidate(
  candidate: ProductCandidate,
  fingerprint: StyleFingerprint,
  focus?: UserFocus,
  constraints?: SearchConstraints,
  context?: { moodboardId?: string; preferenceProfile?: PreferenceProfile },
): ScoreBreakdown {
  if (constraintBlocks(candidate, constraints)) {
    return {
      style: 0,
      focus: 0,
      price: 0,
      feedback: 0,
      total: -1,
      matchedTokens: [],
      blockedByConstraint: true,
      reasons: ["blocked by constraint"],
    };
  }

  const focusSets = resolveFocusSets(focus, context?.moodboardId);

  const titleMatch = countTokenMatches(fingerprint.tokens, tokenizeText(candidate.title));
  const colorMatch = countTokenMatches(fingerprint.colors, candidate.colors);
  const materialMatch = countTokenMatches(fingerprint.materials, candidate.materials);
  const silhouetteMatch = countTokenMatches(fingerprint.silhouettes, candidate.silhouettes);
  const patternMatch = countTokenMatches(fingerprint.patterns, candidate.patterns);
  const vibeMatch = countTokenMatches(fingerprint.vibes, candidate.vibes);
  const brandMatch = countTokenMatches(fingerprint.brands, [candidate.brand]);
  const designerMatch = countTokenMatches(fingerprint.designers, [candidate.designer]);

  const fingerprintWeight = Math.max(1, totalFingerprintWeight(fingerprint));
  const styleRaw =
    titleMatch.score * 0.5 +
    colorMatch.score +
    materialMatch.score +
    silhouetteMatch.score +
    patternMatch.score +
    vibeMatch.score +
    brandMatch.score * 0.5 +
    designerMatch.score * 0.5;
  const style = clampScore(styleRaw / fingerprintWeight);

  const focusMatches = mergeUniqueTokens(
    candidate.brand ? [candidate.brand] : undefined,
    candidate.designer ? [candidate.designer] : undefined,
  );

  let focusScore = 0;
  const brandKey = normalizeToken(candidate.brand);
  const designerKey = normalizeToken(candidate.designer);

  if (brandKey && focusSets.preferredBrands.includes(brandKey)) {
    focusScore += FOCUS_BOOST_WEIGHT;
  }
  if (designerKey && focusSets.preferredDesigners.includes(designerKey)) {
    focusScore += FOCUS_BOOST_WEIGHT;
  }
  if (brandKey && focusSets.avoidedBrands.includes(brandKey)) {
    focusScore += FOCUS_PENALTY_WEIGHT;
  }
  if (designerKey && focusSets.avoidedDesigners.includes(designerKey)) {
    focusScore += FOCUS_PENALTY_WEIGHT;
  }

  const preferenceProfile = context?.preferenceProfile;
  if (preferenceProfile) {
    if (brandKey && typeof preferenceProfile.preferredBrands[brandKey] === "number") {
      focusScore += Math.min(FOCUS_BOOST_WEIGHT, preferenceProfile.preferredBrands[brandKey] * 0.02);
    }
    if (designerKey && typeof preferenceProfile.preferredDesigners[designerKey] === "number") {
      focusScore += Math.min(FOCUS_BOOST_WEIGHT, preferenceProfile.preferredDesigners[designerKey] * 0.02);
    }
    if (brandKey && typeof preferenceProfile.avoidedBrands[brandKey] === "number") {
      focusScore += Math.max(FOCUS_PENALTY_WEIGHT, -preferenceProfile.avoidedBrands[brandKey] * 0.02);
    }
    if (designerKey && typeof preferenceProfile.avoidedDesigners[designerKey] === "number") {
      focusScore += Math.max(FOCUS_PENALTY_WEIGHT, -preferenceProfile.avoidedDesigners[designerKey] * 0.02);
    }
  }

  const priceScore = scorePrice(candidate, constraints, fingerprint);

  const feedbackWeights = context?.preferenceProfile;
  let feedbackScore = 0;
  if (feedbackWeights) {
    const brandKey = normalizeToken(candidate.brand);
    const designerKey = normalizeToken(candidate.designer);
    if (brandKey) {
      feedbackScore += (feedbackWeights.preferredBrands[brandKey] ?? 0) * FEEDBACK_WEIGHT;
      feedbackScore -= (feedbackWeights.avoidedBrands[brandKey] ?? 0) * FEEDBACK_WEIGHT;
    }
    if (designerKey) {
      feedbackScore += (feedbackWeights.preferredDesigners[designerKey] ?? 0) * FEEDBACK_WEIGHT;
      feedbackScore -= (feedbackWeights.avoidedDesigners[designerKey] ?? 0) * FEEDBACK_WEIGHT;
    }
  }

  const total = clampScore(style + focusScore + priceScore + feedbackScore);

  const reasons = [
    ...titleMatch.matches.map((value) => `title:${value}`),
    ...colorMatch.matches.map((value) => `color:${value}`),
    ...materialMatch.matches.map((value) => `material:${value}`),
    ...silhouetteMatch.matches.map((value) => `silhouette:${value}`),
    ...patternMatch.matches.map((value) => `pattern:${value}`),
    ...vibeMatch.matches.map((value) => `vibe:${value}`),
  ];

  if (brandKey) {
    reasons.push(`brand:${brandKey}`);
  }
  if (designerKey) {
    reasons.push(`designer:${designerKey}`);
  }
  if (priceScore !== 0) {
    reasons.push(priceScore > 0 ? "price:within-range" : "price:outlier");
  }
  if (focusScore !== 0) {
    reasons.push(focusScore > 0 ? "focus:boost" : "focus:penalty");
  }
  if (feedbackScore !== 0) {
    reasons.push("feedback:adjustment");
  }

  return {
    style,
    focus: focusScore,
    price: priceScore,
    feedback: feedbackScore,
    total,
    matchedTokens: mergeUniqueTokens(
      colorMatch.matches,
      materialMatch.matches,
      silhouetteMatch.matches,
      patternMatch.matches,
      vibeMatch.matches,
      focusMatches,
    ),
    blockedByConstraint: false,
    reasons,
  };
}

export function rankCandidates(
  candidates: ProductCandidate[],
  fingerprint: StyleFingerprint,
  focus?: UserFocus,
  constraints?: SearchConstraints,
  context?: { moodboardId?: string; preferenceProfile?: PreferenceProfile },
): RankedCandidate[] {
  return candidates
    .map((candidate) => ({
      candidate,
      breakdown: scoreCandidate(candidate, fingerprint, focus, constraints, context),
    }))
    .filter(({ breakdown }) => !breakdown.blockedByConstraint)
    .map(({ candidate, breakdown }) => ({
      candidate,
      score: breakdown.total,
      breakdown,
    }))
    .sort((left, right) => {
      if (right.score !== left.score) {
        return right.score - left.score;
      }
      return left.candidate.id.localeCompare(right.candidate.id);
    });
}

export function updatePreferenceProfile(
  profile: PreferenceProfile,
  signal: InteractionSignal,
  candidate?: ProductCandidate,
): PreferenceProfile {
  const next: PreferenceProfile = {
    preferredDesigners: { ...profile.preferredDesigners },
    preferredBrands: { ...profile.preferredBrands },
    avoidedDesigners: { ...profile.avoidedDesigners },
    avoidedBrands: { ...profile.avoidedBrands },
    preferredPrice: profile.preferredPrice ? { ...profile.preferredPrice } : undefined,
    lastUpdatedAt: new Date().toISOString(),
  };

  const brand = normalizeToken(signal.brand ?? candidate?.brand);
  const designer = normalizeToken(signal.designer ?? candidate?.designer);
  const price = signal.price ?? candidate?.price;

  const bump = (kind: InteractionKind): number => {
    switch (kind) {
      case "purchase":
        return PURCHASE_WEIGHT;
      case "save":
      case "archive":
        return SAVE_WEIGHT;
      case "like":
        return LIKE_WEIGHT;
      case "click":
        return CLICK_WEIGHT;
      case "dislike":
        return DISLIKE_WEIGHT;
      case "ignore":
        return IGNORE_WEIGHT;
      default:
        return 0;
    }
  };

  const delta = bump(signal.kind);

  const apply = (bucket: Record<string, number>, key: string | undefined, amount: number) => {
    if (!key || amount === 0) {
      return;
    }
    bucket[key] = Math.max(0, (bucket[key] ?? 0) + amount);
    if (bucket[key] === 0) {
      delete bucket[key];
    }
  };

  if (delta > 0) {
    apply(next.preferredBrands, brand, delta);
    apply(next.preferredDesigners, designer, delta);
  } else if (delta < 0) {
    apply(next.avoidedBrands, brand, Math.abs(delta));
    apply(next.avoidedDesigners, designer, Math.abs(delta));
  }

  if (typeof price === "number") {
    if (delta > 0) {
      next.preferredPrice = {
        min: typeof next.preferredPrice?.min === "number" ? Math.min(next.preferredPrice.min, price) : price,
        max: typeof next.preferredPrice?.max === "number" ? Math.max(next.preferredPrice.max, price) : price,
      };
    }
    if (delta < 0 && next.preferredPrice) {
      const spread = Math.max(5, price * 0.08);
      next.preferredPrice = {
        min: next.preferredPrice.min,
        max: Math.max(next.preferredPrice.max ?? price, price + spread),
      };
    }
  }

  return next;
}

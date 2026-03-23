import type { StyleProfile, StyleSignal } from "@stylematch/shared-types";

export interface ImageDescriptor {
  imageId: string;
  tags: string[];
  dominantColors: string[];
  materials: string[];
  silhouettes: string[];
  vibes: string[];
}

const signalWeight = (count: number, total: number): number =>
  Number((count / Math.max(total, 1)).toFixed(3));

export function buildStyleSignals(images: ImageDescriptor[]): StyleSignal[] {
  const bucket = new Map<string, number>();
  const total = images.length;

  for (const image of images) {
    for (const v of image.silhouettes) bucket.set(`silhouette:${v}`, (bucket.get(`silhouette:${v}`) ?? 0) + 1);
    for (const v of image.dominantColors) bucket.set(`color:${v}`, (bucket.get(`color:${v}`) ?? 0) + 1);
    for (const v of image.materials) bucket.set(`material:${v}`, (bucket.get(`material:${v}`) ?? 0) + 1);
    for (const v of image.vibes) bucket.set(`vibe:${v}`, (bucket.get(`vibe:${v}`) ?? 0) + 1);
  }

  return [...bucket.entries()]
    .map(([key, count]) => {
      const [category, value] = key.split(":");
      return {
        category: category as StyleSignal["category"],
        value,
        weight: signalWeight(count, total)
      };
    })
    .sort((a, b) => b.weight - a.weight)
    .slice(0, 30);
}

export function createStyleProfile(params: {
  profileId: string;
  userId: string;
  label: string;
  images: ImageDescriptor[];
}): StyleProfile {
  const signals = buildStyleSignals(params.images);
  const confidence = Number(Math.min(0.95, 0.5 + signals.length * 0.01).toFixed(2));
  const now = new Date().toISOString();

  return {
    id: params.profileId,
    userId: params.userId,
    label: params.label,
    confidence,
    signals,
    excludedSignals: [],
    createdAt: now,
    updatedAt: now
  };
}

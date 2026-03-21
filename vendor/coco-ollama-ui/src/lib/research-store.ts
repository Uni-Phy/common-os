import { promises as fs } from "fs";
import path from "path";
import { ResearchTopic } from "@/types/modules";

const DATA_DIR = path.join(process.cwd(), "data");
const DATA_FILE = path.join(DATA_DIR, "research-topics.json");

interface ResearchDataFile {
  topics: ResearchTopic[];
  updatedAt: string;
}

const nowIso = () => new Date().toISOString();

const cadenceToMs: Record<ResearchTopic["cadence"], number> = {
  daily: 24 * 60 * 60 * 1000,
  weekly: 7 * 24 * 60 * 60 * 1000,
  monthly: 30 * 24 * 60 * 60 * 1000,
};

function computeNextRunAt(cadence: ResearchTopic["cadence"], from = Date.now()) {
  return new Date(from + cadenceToMs[cadence]).toISOString();
}

async function ensureStore() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  try {
    await fs.access(DATA_FILE);
  } catch {
    const seed: ResearchDataFile = { topics: [], updatedAt: nowIso() };
    await fs.writeFile(DATA_FILE, JSON.stringify(seed, null, 2), "utf-8");
  }
}

async function readStore(): Promise<ResearchDataFile> {
  await ensureStore();
  const raw = await fs.readFile(DATA_FILE, "utf-8");
  return JSON.parse(raw) as ResearchDataFile;
}

async function writeStore(data: ResearchDataFile) {
  await fs.writeFile(
    DATA_FILE,
    JSON.stringify({ ...data, updatedAt: nowIso() }, null, 2),
    "utf-8"
  );
}

export async function listResearchTopics() {
  const data = await readStore();
  return data.topics;
}

export async function createResearchTopic(
  topic: Omit<ResearchTopic, "id" | "updatedAt" | "createdAt" | "nextRunAt" | "runCount">
) {
  const data = await readStore();
  const created: ResearchTopic = {
    ...topic,
    id: crypto.randomUUID(),
    createdAt: nowIso(),
    updatedAt: nowIso(),
    nextRunAt: computeNextRunAt(topic.cadence),
    runCount: 0,
  };
  data.topics.unshift(created);
  await writeStore(data);
  return created;
}

export async function updateResearchTopic(
  id: string,
  updates: Partial<ResearchTopic>
) {
  const data = await readStore();
  data.topics = data.topics.map((topic) => {
    if (topic.id !== id) return topic;
    const cadence = updates.cadence ?? topic.cadence;
    return {
      ...topic,
      ...updates,
      cadence,
      nextRunAt:
        updates.nextRunAt ??
        (updates.cadence ? computeNextRunAt(cadence) : topic.nextRunAt),
      updatedAt: nowIso(),
    };
  });
  await writeStore(data);
  return data.topics.find((t) => t.id === id) ?? null;
}

export async function deleteResearchTopic(id: string) {
  const data = await readStore();
  const before = data.topics.length;
  data.topics = data.topics.filter((topic) => topic.id !== id);
  await writeStore(data);
  return before !== data.topics.length;
}

export async function runDueResearchTopics() {
  const data = await readStore();
  const now = Date.now();
  const processed: ResearchTopic[] = [];

  data.topics = data.topics.map((topic) => {
    if (topic.status !== "active") return topic;
    const next = topic.nextRunAt ? new Date(topic.nextRunAt).getTime() : 0;
    if (Number.isFinite(next) && next > now) return topic;

    const summary = `Research check executed for "${topic.topic}" at ${nowIso()}. Sources reviewed: ${topic.sources.length}.`;
    const updated: ResearchTopic = {
      ...topic,
      lastRunAt: nowIso(),
      nextRunAt: computeNextRunAt(topic.cadence, now),
      runCount: (topic.runCount ?? 0) + 1,
      lastSummary: summary,
      updatedAt: nowIso(),
    };
    processed.push(updated);
    return updated;
  });

  await writeStore(data);
  return { processedCount: processed.length, processed };
}

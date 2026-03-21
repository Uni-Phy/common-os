export interface PresetQuestion {
  id: string;
  category: string;
  content: string;
}

export interface KnowledgeTopic {
  id: string;
  title: string;
  domain: string;
  objective: string;
  createdAt: string;
}

export interface ResearchTopic {
  id: string;
  topic: string;
  objective: string;
  cadence: "daily" | "weekly" | "monthly";
  sources: string[];
  notes: string;
  status: "active" | "paused";
  updatedAt: string;
  createdAt?: string;
  lastRunAt?: string;
  nextRunAt?: string;
  runCount?: number;
  lastSummary?: string;
}

export interface BenchmarkCase {
  id: string;
  task: string;
  prompt: string;
  expectedCriteria: string;
  score: number;
  notes: string;
}

export interface BenchmarkRun {
  id: string;
  model: string;
  suiteName: string;
  createdAt: string;
  cases: BenchmarkCase[];
}

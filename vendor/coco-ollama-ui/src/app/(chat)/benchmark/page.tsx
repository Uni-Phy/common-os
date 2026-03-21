"use client";

import useChatStore from "@/app/hooks/useChatStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useMemo, useState } from "react";
import ModuleLayout from "@/components/module-layout";

interface DraftCase {
  task: string;
  prompt: string;
  expectedCriteria: string;
  score: number;
  notes: string;
}

const initialCase: DraftCase = {
  task: "",
  prompt: "",
  expectedCriteria: "",
  score: 0,
  notes: "",
};

export default function BenchmarkPage() {
  const selectedModel = useChatStore((state) => state.selectedModel);
  const benchmarkRuns = useChatStore((state) => state.benchmarkRuns);
  const addBenchmarkRun = useChatStore((state) => state.addBenchmarkRun);
  const removeBenchmarkRun = useChatStore((state) => state.removeBenchmarkRun);

  const [suiteName, setSuiteName] = useState("General Suitability");
  const [draft, setDraft] = useState<DraftCase>(initialCase);
  const [cases, setCases] = useState<DraftCase[]>([]);

  const average = useMemo(() => {
    if (cases.length === 0) return 0;
    return Math.round((cases.reduce((acc, c) => acc + c.score, 0) / cases.length) * 10) / 10;
  }, [cases]);

  return (
    <ModuleLayout>
      <main className="min-h-screen p-6 max-w-5xl mx-auto">
        <h1 className="text-2xl font-semibold mb-2">Benchmark Module</h1>
        <p className="text-muted-foreground mb-6">
          Build manual benchmark suites to evaluate model performance and task suitability.
        </p>

        <div className="border rounded-lg p-4 space-y-3">
          <Input value={suiteName} onChange={(e) => setSuiteName(e.target.value)} placeholder="Suite name" />
          <Input value={draft.task} onChange={(e) => setDraft((s) => ({ ...s, task: e.target.value }))} placeholder="Task (e.g. summarization)" />
          <Textarea value={draft.prompt} onChange={(e) => setDraft((s) => ({ ...s, prompt: e.target.value }))} placeholder="Prompt used for testing" />
          <Input
            value={draft.expectedCriteria}
            onChange={(e) => setDraft((s) => ({ ...s, expectedCriteria: e.target.value }))}
            placeholder="Expected criteria (e.g. factuality, brevity)"
          />
          <Input
            type="number"
            min={0}
            max={10}
            value={draft.score}
            onChange={(e) => setDraft((s) => ({ ...s, score: Number(e.target.value || 0) }))}
            placeholder="Score 0-10"
          />
          <Textarea value={draft.notes} onChange={(e) => setDraft((s) => ({ ...s, notes: e.target.value }))} placeholder="Notes" />
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => {
                if (!draft.task.trim() || !draft.prompt.trim()) return;
                setCases((prev) => [...prev, draft]);
                setDraft(initialCase);
              }}
            >
              Add case
            </Button>
            <Button
              onClick={() => {
                if (!selectedModel || cases.length === 0) return;
                addBenchmarkRun({
                  model: selectedModel,
                  suiteName,
                  cases: cases.map((c, idx) => ({
                    id: `${idx + 1}`,
                    ...c,
                  })),
                });
                setCases([]);
              }}
              disabled={!selectedModel || cases.length === 0}
            >
              Save benchmark run
            </Button>
          </div>
          <p className="text-sm text-muted-foreground">
            Draft cases: {cases.length} • Average score: {average} / 10
          </p>
        </div>

        <div className="mt-8 space-y-3">
          {benchmarkRuns.map((run) => {
            const runAvg =
              run.cases.length === 0
                ? 0
                : Math.round((run.cases.reduce((acc, c) => acc + c.score, 0) / run.cases.length) * 10) / 10;
            return (
              <div key={run.id} className="border rounded-lg p-4">
                <div className="flex justify-between items-start">
                  <div>
                    <h2 className="font-medium">{run.suiteName}</h2>
                    <p className="text-sm text-muted-foreground">
                      Model: {run.model} • Cases: {run.cases.length} • Avg: {runAvg} / 10
                    </p>
                  </div>
                  <Button variant="destructive" onClick={() => removeBenchmarkRun(run.id)}>
                    Remove
                  </Button>
                </div>
              </div>
            );
          })}
          {benchmarkRuns.length === 0 && (
            <p className="text-sm text-muted-foreground">No benchmark runs yet.</p>
          )}
        </div>
      </main>
    </ModuleLayout>
  );
}

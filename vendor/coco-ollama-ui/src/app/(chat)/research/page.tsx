"use client";

import { ResearchTopic } from "@/types/modules";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { useEffect, useState } from "react";
import ModuleLayout from "@/components/module-layout";

export default function ResearchPage() {
  const [topic, setTopic] = useState("");
  const [objective, setObjective] = useState("");
  const [cadence, setCadence] = useState<"daily" | "weekly" | "monthly">("weekly");
  const [sources, setSources] = useState("");
  const [notes, setNotes] = useState("");
  const [researchTopics, setResearchTopics] = useState<ResearchTopic[]>([]);
  const [isLoading, setIsLoading] = useState(false);

  const fetchTopics = async () => {
    const res = await fetch("/api/research/topics", { cache: "no-store" });
    const data = await res.json();
    setResearchTopics(data.topics ?? []);
  };

  useEffect(() => {
    fetchTopics();
  }, []);

  return (
    <ModuleLayout>
      <main className="min-h-screen p-6 max-w-5xl mx-auto">
        <h1 className="text-2xl font-semibold mb-2">Research Module</h1>
        <p className="text-muted-foreground mb-6">
          Track continuous background research topics and internet sources to review on a cadence.
        </p>

        <div className="space-y-3">
          <Input placeholder="Research topic" value={topic} onChange={(e) => setTopic(e.target.value)} />
          <Input placeholder="Objective" value={objective} onChange={(e) => setObjective(e.target.value)} />
          <Input
            placeholder="Cadence: daily | weekly | monthly"
            value={cadence}
            onChange={(e) => {
              const val = e.target.value as "daily" | "weekly" | "monthly";
              if (["daily", "weekly", "monthly"].includes(val)) setCadence(val);
            }}
          />
          <Textarea
            placeholder="Sources (one URL per line)"
            value={sources}
            onChange={(e) => setSources(e.target.value)}
          />
          <Textarea placeholder="Notes" value={notes} onChange={(e) => setNotes(e.target.value)} />
          <div className="flex gap-2 flex-wrap">
            <Button
              onClick={async () => {
                if (!topic.trim() || !objective.trim()) return;
                setIsLoading(true);
                await fetch("/api/research/topics", {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({
                    topic: topic.trim(),
                    objective: objective.trim(),
                    cadence,
                    sources: sources.split("\n").map((s) => s.trim()).filter(Boolean),
                    notes: notes.trim(),
                    status: "active",
                  }),
                });
                setIsLoading(false);
                await fetchTopics();
                setTopic("");
                setObjective("");
                setCadence("weekly");
                setSources("");
                setNotes("");
              }}
              disabled={isLoading}
            >
              Add research topic
            </Button>
            <Button
              variant="outline"
              onClick={async () => {
                setIsLoading(true);
                await fetch("/api/research/cron/run", { method: "POST" });
                setIsLoading(false);
                await fetchTopics();
              }}
              disabled={isLoading}
            >
              Run due research now
            </Button>
            <Button variant="ghost" onClick={fetchTopics} disabled={isLoading}>
              Refresh
            </Button>
          </div>
        </div>

        <div className="mt-8 space-y-3">
          {researchTopics.map((item) => (
            <div key={item.id} className="border rounded-lg p-4">
              <div className="flex justify-between items-start gap-3">
                <div>
                  <h2 className="font-medium">{item.topic}</h2>
                  <p className="text-sm text-muted-foreground">
                    Cadence: {item.cadence} • Status: {item.status}
                  </p>
                  <p className="text-sm mt-1">{item.objective}</p>
                  <p className="text-xs text-muted-foreground mt-1">
                    Last run: {item.lastRunAt ? new Date(item.lastRunAt).toLocaleString() : "never"} •
                    Next run: {item.nextRunAt ? new Date(item.nextRunAt).toLocaleString() : "n/a"} •
                    Runs: {item.runCount ?? 0}
                  </p>
                  {item.lastSummary && (
                    <p className="text-xs mt-1 text-muted-foreground">{item.lastSummary}</p>
                  )}
                  {item.sources.length > 0 && (
                    <ul className="text-sm list-disc ml-4 mt-2">
                      {item.sources.map((src) => (
                        <li key={src}>
                          <a href={src} target="_blank" rel="noreferrer" className="underline">
                            {src}
                          </a>
                        </li>
                      ))}
                    </ul>
                  )}
                </div>
                <div className="flex gap-2">
                  <Button
                    variant="outline"
                    onClick={async () => {
                      await fetch(`/api/research/topics/${item.id}`, {
                        method: "PATCH",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                          status: item.status === "active" ? "paused" : "active",
                        }),
                      });
                      await fetchTopics();
                    }}
                    disabled={isLoading}
                  >
                    {item.status === "active" ? "Pause" : "Resume"}
                  </Button>
                  <Button
                    variant="destructive"
                    onClick={async () => {
                      await fetch(`/api/research/topics/${item.id}`, { method: "DELETE" });
                      await fetchTopics();
                    }}
                    disabled={isLoading}
                  >
                    Remove
                  </Button>
                </div>
              </div>
            </div>
          ))}
          {researchTopics.length === 0 && (
            <p className="text-sm text-muted-foreground">No research topics yet.</p>
          )}
        </div>
      </main>
    </ModuleLayout>
  );
}

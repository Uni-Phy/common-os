"use client";

import useChatStore from "@/app/hooks/useChatStore";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useState } from "react";
import ModuleLayout from "@/components/module-layout";

export default function KnowledgePage() {
  const [title, setTitle] = useState("");
  const [domain, setDomain] = useState("");
  const [objective, setObjective] = useState("");
  const knowledgeTopics = useChatStore((state) => state.knowledgeTopics);
  const addKnowledgeTopic = useChatStore((state) => state.addKnowledgeTopic);
  const removeKnowledgeTopic = useChatStore((state) => state.removeKnowledgeTopic);

  return (
    <ModuleLayout>
      <main className="min-h-screen p-6 max-w-4xl mx-auto">
        <h1 className="text-2xl font-semibold mb-2">Knowledge Module</h1>
        <p className="text-muted-foreground mb-6">
          Store important domains and learning objectives used to design prompt presets and evaluation suites.
        </p>

        <div className="grid gap-3 md:grid-cols-3 mb-4">
          <Input placeholder="Topic title" value={title} onChange={(e) => setTitle(e.target.value)} />
          <Input placeholder="Domain (e.g. finance, coding)" value={domain} onChange={(e) => setDomain(e.target.value)} />
          <Input placeholder="Objective" value={objective} onChange={(e) => setObjective(e.target.value)} />
        </div>
        <Button
          onClick={() => {
            if (!title.trim() || !domain.trim() || !objective.trim()) return;
            addKnowledgeTopic({ title: title.trim(), domain: domain.trim(), objective: objective.trim() });
            setTitle("");
            setDomain("");
            setObjective("");
          }}
        >
          Add topic
        </Button>

        <div className="mt-8 space-y-3">
          {knowledgeTopics.map((topic) => (
            <div key={topic.id} className="border rounded-lg p-4 flex items-start justify-between gap-4">
              <div>
                <h2 className="font-medium">{topic.title}</h2>
                <p className="text-sm text-muted-foreground">Domain: {topic.domain}</p>
                <p className="text-sm">{topic.objective}</p>
              </div>
              <Button variant="destructive" onClick={() => removeKnowledgeTopic(topic.id)}>
                Remove
              </Button>
            </div>
          ))}
          {knowledgeTopics.length === 0 && (
            <p className="text-sm text-muted-foreground">No knowledge topics yet.</p>
          )}
        </div>
      </main>
    </ModuleLayout>
  );
}

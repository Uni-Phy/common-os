"use client";

import useChatStore from "@/app/hooks/useChatStore";
import { Button } from "./ui/button";

interface PresetQuestionsProps {
  onSelect: (question: string) => void;
}

export default function PresetQuestions({ onSelect }: PresetQuestionsProps) {
  const presetQuestions = useChatStore((state) => state.presetQuestions);

  return (
    <div className="w-full max-w-2xl">
      <p className="text-sm text-muted-foreground mb-3">Try a preset prompt</p>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
        {presetQuestions.map((preset) => (
          <Button
            key={preset.id}
            variant="outline"
            className="justify-start text-left h-auto whitespace-normal py-3"
            onClick={() => onSelect(preset.content)}
          >
            <span className="text-xs uppercase tracking-wide mr-2 text-muted-foreground">
              {preset.category}
            </span>
            {preset.content}
          </Button>
        ))}
      </div>
    </div>
  );
}

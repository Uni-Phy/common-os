import { createResearchTopic, listResearchTopics } from "@/lib/research-store";

export const dynamic = "force-dynamic";

export async function GET() {
  const topics = await listResearchTopics();
  return Response.json({ topics });
}

export async function POST(req: Request) {
  const body = await req.json();
  const created = await createResearchTopic({
    topic: body.topic,
    objective: body.objective,
    cadence: body.cadence,
    sources: Array.isArray(body.sources) ? body.sources : [],
    notes: body.notes ?? "",
    status: body.status ?? "active",
  });
  return Response.json({ topic: created }, { status: 201 });
}

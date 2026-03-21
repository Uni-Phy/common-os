import { runDueResearchTopics } from "@/lib/research-store";

export const dynamic = "force-dynamic";

export async function POST() {
  const result = await runDueResearchTopics();
  return Response.json(result);
}

export async function GET() {
  const result = await runDueResearchTopics();
  return Response.json(result);
}

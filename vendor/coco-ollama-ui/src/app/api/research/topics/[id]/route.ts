import { deleteResearchTopic, updateResearchTopic } from "@/lib/research-store";

export const dynamic = "force-dynamic";

export async function PATCH(
  req: Request,
  { params }: { params: { id: string } }
) {
  const body = await req.json();
  const updated = await updateResearchTopic(params.id, body);
  if (!updated) {
    return Response.json({ error: "Not found" }, { status: 404 });
  }
  return Response.json({ topic: updated });
}

export async function DELETE(
  _req: Request,
  { params }: { params: { id: string } }
) {
  const deleted = await deleteResearchTopic(params.id);
  return Response.json({ deleted });
}

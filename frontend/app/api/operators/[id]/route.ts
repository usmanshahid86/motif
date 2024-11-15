import { NextResponse } from "next/server";
import { z } from "zod";
import operators from "@/lib/operators.json";

const requestSchema = z.object({
  method: z.enum(["get_address"]),
  body: z.record(z.string()),
});

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const body = await request.json();

  const parsed = requestSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid request" }, { status: 400 });
  }

  const { method, body: requestBody } = parsed.data;

  const id = (await params).id;

  const operator = operators["operators"].find(
    (operator) => operator.id === id
  );

  if (!operator) {
    return NextResponse.json({ error: "Operator not found" }, { status: 404 });
  }

  const response = await fetch(`${operator.link}/eigen/${method}`, {
    method: "POST",
    body: JSON.stringify(requestBody),
  });

  const result = await response.json();

  return NextResponse.json(result);
}

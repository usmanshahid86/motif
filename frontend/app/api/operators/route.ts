import { NextResponse } from "next/server";
import operators from "@/lib/operators.json";

export async function GET() {
  return NextResponse.json(operators.operators);
}

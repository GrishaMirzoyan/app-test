import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { requireVerified } from "@/lib/gate";
import { putObject } from "@/lib/storage";

const MAX_BYTES = 15 * 1024 * 1024;
const ALLOWED = ["image/jpeg", "image/png", "image/webp", "image/gif"];

// Upload a yearbook or photo (§4.6). Verified-members-only; never public.
export async function POST(req: Request) {
  const me = await requireVerified();
  const form = await req.formData();

  const file = form.get("file");
  if (!(file instanceof File)) {
    return NextResponse.json({ error: "A file is required." }, { status: 400 });
  }
  if (!ALLOWED.includes(file.type)) {
    return NextResponse.json({ error: "Unsupported image type." }, { status: 400 });
  }
  if (file.size > MAX_BYTES) {
    return NextResponse.json({ error: "Image too large (15MB max)." }, { status: 400 });
  }

  const type = form.get("type") === "yearbook" ? "yearbook" : "photo";
  const title = String(form.get("title") ?? "").trim() || "Untitled";
  const roomTag = String(form.get("roomTag") ?? "").trim() || null;
  const yearRaw = form.get("year");
  const rangeStartRaw = form.get("yearRangeStart");
  const rangeEndRaw = form.get("yearRangeEnd");
  const year = yearRaw ? parseInt(String(yearRaw), 10) : null;
  const yearRangeStart = rangeStartRaw ? parseInt(String(rangeStartRaw), 10) : null;
  const yearRangeEnd = rangeEndRaw ? parseInt(String(rangeEndRaw), 10) : null;

  const buf = Buffer.from(await file.arrayBuffer());
  const { key } = await putObject(buf, file.type);

  const item = await prisma.archiveItem.create({
    data: {
      uploaderId: me.id,
      type,
      title,
      roomTag,
      year: Number.isFinite(year as number) ? year : null,
      yearRangeStart: Number.isFinite(yearRangeStart as number) ? yearRangeStart : null,
      yearRangeEnd: Number.isFinite(yearRangeEnd as number) ? yearRangeEnd : null,
      imageRef: key,
      visibility: "verified_members",
    },
  });

  return NextResponse.json({ ok: true, id: item.id });
}

import { NextResponse } from "next/server";
import { currentMember } from "@/lib/gate";
import { getObject } from "@/lib/storage";

// Archive images are NEVER public (§1, §3.5). They are served only through this
// route, which re-checks the verification gate on every request. The object
// store itself stays private.
export async function GET(
  _req: Request,
  { params }: { params: Promise<{ key: string[] }> },
) {
  const me = await currentMember();
  if (!me || me.verificationStatus !== "verified") {
    return new NextResponse("Forbidden", { status: 403 });
  }

  const { key } = await params;
  const obj = await getObject(key.join("/"));
  if (!obj) return new NextResponse("Not found", { status: 404 });

  return new NextResponse(new Uint8Array(obj.body), {
    headers: {
      "Content-Type": obj.contentType,
      // Private, authenticated content — do not let shared caches keep it.
      "Cache-Control": "private, max-age=3600",
      "X-Robots-Tag": "noindex, nofollow",
    },
  });
}

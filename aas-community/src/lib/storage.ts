// Object store for archive images (§1, §3.5). S3-compatible in a NON-RUSSIAN
// region in production; a local filesystem store under ./.uploads for dev when
// no S3 credentials are configured. Archive images are never public — they are
// served through an authenticated route that re-checks the verification gate.

import { promises as fs } from "fs";
import path from "path";
import crypto from "crypto";

const useS3 = !!(process.env.S3_BUCKET && process.env.S3_ACCESS_KEY_ID);

const LOCAL_DIR = path.join(process.cwd(), ".uploads");

export interface StoredObject {
  key: string;
}

export async function putObject(
  body: Buffer,
  contentType: string,
): Promise<StoredObject> {
  const ext = contentType.split("/")[1]?.replace(/[^a-z0-9]/gi, "") || "bin";
  const key = `${new Date().getUTCFullYear()}/${crypto.randomUUID()}.${ext}`;

  if (useS3) {
    const { S3Client, PutObjectCommand } = await import("@aws-sdk/client-s3");
    const client = new S3Client({
      region: process.env.S3_REGION,
      endpoint: process.env.S3_ENDPOINT || undefined,
      forcePathStyle: !!process.env.S3_ENDPOINT,
      credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY_ID!,
        secretAccessKey: process.env.S3_SECRET_ACCESS_KEY!,
      },
    });
    await client.send(
      new PutObjectCommand({
        Bucket: process.env.S3_BUCKET!,
        Key: key,
        Body: body,
        ContentType: contentType,
        // Never public — access is brokered by the app, not the bucket.
        ACL: "private",
      }),
    );
    return { key };
  }

  // Local fallback.
  const full = path.join(LOCAL_DIR, key);
  await fs.mkdir(path.dirname(full), { recursive: true });
  await fs.writeFile(full, body);
  return { key };
}

export async function getObject(
  key: string,
): Promise<{ body: Buffer; contentType: string } | null> {
  const contentType = guessContentType(key);
  if (useS3) {
    const { S3Client, GetObjectCommand } = await import("@aws-sdk/client-s3");
    const client = new S3Client({
      region: process.env.S3_REGION,
      endpoint: process.env.S3_ENDPOINT || undefined,
      forcePathStyle: !!process.env.S3_ENDPOINT,
      credentials: {
        accessKeyId: process.env.S3_ACCESS_KEY_ID!,
        secretAccessKey: process.env.S3_SECRET_ACCESS_KEY!,
      },
    });
    try {
      const res = await client.send(
        new GetObjectCommand({ Bucket: process.env.S3_BUCKET!, Key: key }),
      );
      const bytes = await res.Body!.transformToByteArray();
      return { body: Buffer.from(bytes), contentType };
    } catch {
      return null;
    }
  }

  try {
    // Guard against path traversal.
    const full = path.join(LOCAL_DIR, key);
    if (!full.startsWith(LOCAL_DIR)) return null;
    const body = await fs.readFile(full);
    return { body, contentType };
  } catch {
    return null;
  }
}

function guessContentType(key: string): string {
  const ext = key.split(".").pop()?.toLowerCase();
  switch (ext) {
    case "png":
      return "image/png";
    case "webp":
      return "image/webp";
    case "gif":
      return "image/gif";
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    default:
      return "application/octet-stream";
  }
}

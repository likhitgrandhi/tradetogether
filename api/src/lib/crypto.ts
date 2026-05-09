import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

const ALGORITHM = "aes-256-gcm";

function normalizeKey(keyMaterial: string): Buffer {
  const decoded = Buffer.from(keyMaterial, "base64");
  if (decoded.length === 32) {
    return decoded;
  }

  const utf8 = Buffer.from(keyMaterial, "utf8");
  if (utf8.length === 32) {
    return utf8;
  }

  throw new Error("SNAPTRADE_USER_SECRET_ENCRYPTION_KEY must be 32 bytes or base64-encoded 32 bytes");
}

export function encryptSecret(secret: string, keyMaterial: string): string {
  const key = normalizeKey(keyMaterial);
  const iv = randomBytes(12);
  const cipher = createCipheriv(ALGORITHM, key, iv);
  const ciphertext = Buffer.concat([cipher.update(secret, "utf8"), cipher.final()]);
  const tag = cipher.getAuthTag();

  return [iv, tag, ciphertext].map((part) => part.toString("base64url")).join(".");
}

export function decryptSecret(encrypted: string, keyMaterial: string): string {
  const key = normalizeKey(keyMaterial);
  const [ivPart, tagPart, ciphertextPart] = encrypted.split(".");
  if (!ivPart || !tagPart || !ciphertextPart) {
    throw new Error("Invalid encrypted secret payload");
  }

  const decipher = createDecipheriv(ALGORITHM, key, Buffer.from(ivPart, "base64url"));
  decipher.setAuthTag(Buffer.from(tagPart, "base64url"));
  const plaintext = Buffer.concat([
    decipher.update(Buffer.from(ciphertextPart, "base64url")),
    decipher.final()
  ]);

  return plaintext.toString("utf8");
}

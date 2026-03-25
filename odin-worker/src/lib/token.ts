const CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

export function randomString(length: number): string {
  const bytes = new Uint8Array(length);
  crypto.getRandomValues(bytes);
  return Array.from(bytes).map(b => CHARS[b % CHARS.length]).join('');
}

/**
 * Generates a unique token by checking KV for collisions.
 * Retries up to 3 times; throws if all retries collide.
 *
 * @param generateCandidate - Optional injectable for testing; defaults to randomString(length).
 */
export async function generateToken(
  kv: KVNamespace,
  generateCandidate?: () => string,
  length = 8,
): Promise<string> {
  const candidate = generateCandidate ?? (() => randomString(length));
  for (let i = 0; i < 3; i++) {
    const token = candidate();
    const existing = await kv.get(token);
    if (existing === null) return token;
  }
  throw new Error('Token collision after 3 retries');
}

/**
 * Extracts the 8-char token code from either:
 * - A full URL: https://odin-worker.workers.dev/d/aB3kR9mQ → aB3kR9mQ
 * - A bare code: aB3kR9mQ → aB3kR9mQ
 */
export function extractTokenCode(tokenOrUrl: string): string {
  try {
    const url = new URL(tokenOrUrl);
    const segments = url.pathname.split('/').filter(Boolean);
    const dIndex = segments.indexOf('d');
    if (dIndex !== -1 && segments[dIndex + 1]) {
      return segments[dIndex + 1];
    }
  } catch {
    // Not a URL — use as-is
  }
  return tokenOrUrl;
}

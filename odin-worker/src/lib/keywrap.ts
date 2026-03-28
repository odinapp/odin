const WRAP_PREFIX = 'ODK1.';

function encodeBase64Url(bytes: Uint8Array): string {
  const encoded = btoa(String.fromCharCode(...bytes));
  return encoded.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
}

function decodeBase64Url(input: string): Uint8Array {
  const normalized = input.replaceAll('-', '+').replaceAll('_', '/');
  const pad = '='.repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(`${normalized}${pad}`);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function importWrapKey(secret: string): Promise<CryptoKey> {
  const bytes = decodeBase64Url(secret.trim());
  if (bytes.length !== 32) {
    throw new Error('ENCRYPTION_METADATA_KEY must decode to 32 bytes');
  }
  return crypto.subtle.importKey('raw', bytes, 'AES-GCM', false, [
    'encrypt',
    'decrypt',
  ]);
}

export async function wrapEncryptionKey(
  rawKeyBase64Url: string,
  wrapSecret: string,
): Promise<string> {
  const wrapKey = await importWrapKey(wrapSecret);
  const keyBytes = decodeBase64Url(rawKeyBase64Url.trim());
  if (keyBytes.length !== 32) {
    throw new Error('encryptionKey must decode to 32 bytes');
  }
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const cipher = await crypto.subtle.encrypt(
    { name: 'AES-GCM', iv },
    wrapKey,
    keyBytes,
  );
  const payload = new Uint8Array(iv.length + cipher.byteLength);
  payload.set(iv, 0);
  payload.set(new Uint8Array(cipher), iv.length);
  return `${WRAP_PREFIX}${encodeBase64Url(payload)}`;
}

export async function unwrapEncryptionKey(
  wrapped: string,
  wrapSecret: string,
): Promise<Uint8Array> {
  if (!wrapped.startsWith(WRAP_PREFIX)) {
    throw new Error('Unknown wrapped key format');
  }
  const payload = decodeBase64Url(wrapped.slice(WRAP_PREFIX.length));
  if (payload.length <= 12 + 16) {
    throw new Error('Wrapped key payload is too short');
  }
  const iv = payload.slice(0, 12);
  const cipher = payload.slice(12);
  const wrapKey = await importWrapKey(wrapSecret);
  const plain = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv },
    wrapKey,
    cipher,
  );
  return new Uint8Array(plain);
}

const MAGIC = 'ODINENC2';
const VERSION = 2;

function readUint32(bytes: Uint8Array, offset: number): number {
  return new DataView(
    bytes.buffer,
    bytes.byteOffset + offset,
    4,
  ).getUint32(0, false);
}

function utf8(input: Uint8Array): string {
  return new TextDecoder().decode(input);
}

export function isEncryptedContainer(bytes: Uint8Array): boolean {
  if (bytes.length < MAGIC.length + 1) {
    return false;
  }
  return utf8(bytes.subarray(0, MAGIC.length)) === MAGIC;
}

export async function decryptContainerPayload(
  bytes: Uint8Array,
  encryptionKey: Uint8Array,
): Promise<{ payload: Uint8Array; manifest: Record<string, unknown> }> {
  if (!isEncryptedContainer(bytes)) {
    throw new Error('Payload is not an ODIN encrypted container');
  }

  let offset = 0;
  offset += MAGIC.length;
  const version = bytes[offset++];
  if (version !== VERSION) {
    throw new Error(`Unsupported container version: ${version}`);
  }

  // Keep nonce as a small copy (12 bytes) — WebCrypto requires a stable buffer for the IV.
  const nonce = bytes.slice(offset, offset + 12);
  offset += 12;
  const cipherLen = readUint32(bytes, offset);
  offset += 4;
  if (cipherLen <= 0 || bytes.length < offset + cipherLen + 16) {
    throw new Error('Corrupted encrypted payload');
  }

  // cipher and tag are contiguous in `bytes`; pass a zero-copy subarray view
  // directly to WebCrypto instead of allocating two intermediate copies.
  const cipherWithTag = bytes.subarray(offset, offset + cipherLen + 16);

  const aesKey = await crypto.subtle.importKey(
    'raw',
    encryptionKey,
    'AES-GCM',
    false,
    ['decrypt'],
  );
  const plainBuffer = await crypto.subtle.decrypt(
    { name: 'AES-GCM', iv: nonce },
    aesKey,
    cipherWithTag,
  );
  const plain = new Uint8Array(plainBuffer);

  if (plain.length < 4) {
    throw new Error('Decrypted payload is too short');
  }
  const manifestLen = readUint32(plain, 0);
  if (manifestLen <= 0 || plain.length < 4 + manifestLen) {
    throw new Error('Corrupted decrypted manifest');
  }
  // manifest JSON is small — a copy here is negligible.
  const manifestRaw = utf8(plain.subarray(4, 4 + manifestLen));
  const manifest = JSON.parse(manifestRaw) as Record<string, unknown>;
  // Return a zero-copy view of the decrypted plainBuffer for the payload.
  const payload = plain.subarray(4 + manifestLen);
  return { payload, manifest };
}

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
  return utf8(bytes.slice(0, MAGIC.length)) === MAGIC;
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

  const nonce = bytes.slice(offset, offset + 12);
  offset += 12;
  const cipherLen = readUint32(bytes, offset);
  offset += 4;
  if (cipherLen <= 0 || bytes.length < offset + cipherLen + 16) {
    throw new Error('Corrupted encrypted payload');
  }

  const cipher = bytes.slice(offset, offset + cipherLen);
  offset += cipherLen;
  const tag = bytes.slice(offset, offset + 16);

  const aesKey = await crypto.subtle.importKey(
    'raw',
    encryptionKey,
    'AES-GCM',
    false,
    ['decrypt'],
  );
  const cipherWithTag = new Uint8Array(cipher.length + tag.length);
  cipherWithTag.set(cipher, 0);
  cipherWithTag.set(tag, cipher.length);
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
  const manifestRaw = utf8(plain.slice(4, 4 + manifestLen));
  const manifest = JSON.parse(manifestRaw) as Record<string, unknown>;
  const payload = plain.slice(4 + manifestLen);
  return { payload, manifest };
}

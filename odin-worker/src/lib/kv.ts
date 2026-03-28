export interface UploadMetadata {
  r2Key: string;
  filename: string;
  size: number;
  uploadedAt: string;
  expiresAt: string;
  deleteToken: string;
  manifestPreview?: Record<string, unknown>;
  wrappedEncryptionKey?: string;
  encrypted?: boolean;
  fileCount?: number;
  originalTotalFileSize?: number;
  isArchive?: boolean;
}

export interface CleanupEntry {
  token: string;
  r2Key: string;
  expiresAt: string;
}

export async function getMetadata(kv: KVNamespace, token: string): Promise<UploadMetadata | null> {
  const value = await kv.get(token);
  if (value === null) return null;
  return JSON.parse(value) as UploadMetadata;
}

export async function setMetadata(
  kv: KVNamespace,
  token: string,
  metadata: UploadMetadata,
): Promise<void> {
  await kv.put(token, JSON.stringify(metadata), { expirationTtl: 86400 });
}

export async function deleteMetadata(kv: KVNamespace, token: string): Promise<void> {
  await kv.delete(token);
}

export async function setCleanupEntry(
  kv: KVNamespace,
  token: string,
  entry: CleanupEntry,
): Promise<void> {
  await kv.put(`cleanup:${token}`, JSON.stringify(entry), { expirationTtl: 172800 });
}

export async function deleteCleanupEntry(kv: KVNamespace, token: string): Promise<void> {
  await kv.delete(`cleanup:${token}`);
}

export async function listCleanupEntries(kv: KVNamespace): Promise<CleanupEntry[]> {
  const entries: CleanupEntry[] = [];
  let cursor: string | undefined;

  do {
    const result = await kv.list({ prefix: 'cleanup:', cursor, limit: 1000 });
    const values = await Promise.all(result.keys.map(key => kv.get(key.name)));
    for (const value of values) {
      if (value !== null) {
        try {
          entries.push(JSON.parse(value) as CleanupEntry);
        } catch {
          // Skip malformed entries — they'll age out with KV TTL
        }
      }
    }
    cursor = result.list_complete ? undefined : result.cursor;
  } while (cursor !== undefined);

  return entries;
}

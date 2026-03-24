export interface UploadMetadata {
  r2Key: string;
  filename: string;
  size: number;
  uploadedAt: string;
  expiresAt: string;
  deleteToken: string;
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
    for (const key of result.keys) {
      const value = await kv.get(key.name);
      if (value !== null) {
        entries.push(JSON.parse(value) as CleanupEntry);
      }
    }
    cursor = result.list_complete ? undefined : result.cursor;
  } while (cursor !== undefined);

  return entries;
}

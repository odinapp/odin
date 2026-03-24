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
  const list = await kv.list({ prefix: 'cleanup:' });
  const entries: CleanupEntry[] = [];
  for (const key of list.keys) {
    const value = await kv.get(key.name);
    if (value !== null) {
      entries.push(JSON.parse(value) as CleanupEntry);
    }
  }
  return entries;
}

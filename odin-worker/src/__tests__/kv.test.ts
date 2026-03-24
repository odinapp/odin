import { describe, it, expect, beforeEach } from 'vitest';
import { env } from 'cloudflare:test';
import {
  setMetadata, getMetadata, deleteMetadata,
  setCleanupEntry, deleteCleanupEntry, listCleanupEntries,
  type UploadMetadata, type CleanupEntry,
} from '../lib/kv';

const SAMPLE_META: UploadMetadata = {
  r2Key: 'abc12345/file.txt',
  filename: 'file.txt',
  size: 1234,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'xxxxxxxxxxxxxxxx',
};

const SAMPLE_CLEANUP: CleanupEntry = {
  token: 'abc12345',
  r2Key: 'abc12345/file.txt',
  expiresAt: '2026-03-25T00:00:00.000Z',
};

describe('metadata helpers', () => {
  beforeEach(async () => {
    await env.KV_METADATA.delete('kv00001');
    await env.KV_METADATA.delete('kv00002');
  });

  it('returns null for missing key', async () => {
    expect(await getMetadata(env.KV_METADATA, 'missing')).toBeNull();
  });

  it('round-trips metadata through KV', async () => {
    await setMetadata(env.KV_METADATA, 'kv00001', SAMPLE_META);
    const result = await getMetadata(env.KV_METADATA, 'kv00001');
    expect(result).toEqual(SAMPLE_META);
  });

  it('deletes metadata', async () => {
    await setMetadata(env.KV_METADATA, 'kv00002', SAMPLE_META);
    await deleteMetadata(env.KV_METADATA, 'kv00002');
    expect(await getMetadata(env.KV_METADATA, 'kv00002')).toBeNull();
  });
});

describe('cleanup index helpers', () => {
  beforeEach(async () => {
    await env.KV_METADATA.delete('cleanup:kv00003');
    await env.KV_METADATA.delete('cleanup:kv00004');
  });

  it('lists cleanup entries by prefix', async () => {
    await setCleanupEntry(env.KV_METADATA, 'kv00003', { ...SAMPLE_CLEANUP, token: 'kv00003' });
    const entries = await listCleanupEntries(env.KV_METADATA);
    expect(entries.some(e => e.token === 'kv00003')).toBe(true);
  });

  it('deletes cleanup entry', async () => {
    await setCleanupEntry(env.KV_METADATA, 'kv00004', { ...SAMPLE_CLEANUP, token: 'kv00004' });
    await deleteCleanupEntry(env.KV_METADATA, 'kv00004');
    const entries = await listCleanupEntries(env.KV_METADATA);
    expect(entries.some(e => e.token === 'kv00004')).toBe(false);
  });
});

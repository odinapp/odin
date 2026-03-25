import { describe, it, expect, beforeEach } from 'vitest';
import { env } from 'cloudflare:test';
import { randomString, generateToken, extractTokenCode } from '../lib/token';

describe('randomString', () => {
  it('returns a string of the requested length', () => {
    expect(randomString(8)).toHaveLength(8);
    expect(randomString(16)).toHaveLength(16);
  });

  it('only contains alphanumeric characters', () => {
    const s = randomString(100);
    expect(s).toMatch(/^[A-Za-z0-9]+$/);
  });

  it('produces statistically unique outputs across 1000 calls', () => {
    const results = new Set(Array.from({ length: 1000 }, () => randomString(8)));
    expect(results.size).toBe(1000);
  });
});

describe('generateToken', () => {
  beforeEach(async () => {
    // Clean up all keys pre-seeded by collision tests
    for (const k of ['aaaaaaaa', 'bbbbbbbb', 'cccccccc', 'dddddddd', 'eeeeeeee', 'ffffffff']) {
      await env.KV_METADATA.delete(k);
    }
  });

  it('returns an 8-char token when KV has no collision', async () => {
    const token = await generateToken(env.KV_METADATA);
    expect(token).toHaveLength(8);
    expect(token).toMatch(/^[A-Za-z0-9]{8}$/);
  });

  it('retries and succeeds when the first two attempts collide', async () => {
    await env.KV_METADATA.put('aaaaaaaa', 'taken');
    await env.KV_METADATA.put('bbbbbbbb', 'taken');
    const candidates = ['aaaaaaaa', 'bbbbbbbb', 'cccccccc'];
    let i = 0;
    const token = await generateToken(env.KV_METADATA, () => candidates[i++]);
    expect(token).toBe('cccccccc');
  });

  it('throws after 3 consecutive collisions', async () => {
    await env.KV_METADATA.put('dddddddd', 'taken');
    await env.KV_METADATA.put('eeeeeeee', 'taken');
    await env.KV_METADATA.put('ffffffff', 'taken');
    const candidates = ['dddddddd', 'eeeeeeee', 'ffffffff'];
    let i = 0;
    await expect(generateToken(env.KV_METADATA, () => candidates[i++])).rejects.toThrow();
  });
});

describe('extractTokenCode', () => {
  it('extracts 8-char code from a full /d/ URL', () => {
    expect(extractTokenCode('https://odin-worker.workers.dev/d/aB3kR9mQ')).toBe('aB3kR9mQ');
  });

  it('returns the input unchanged when already a bare code', () => {
    expect(extractTokenCode('aB3kR9mQ')).toBe('aB3kR9mQ');
  });

  it('handles URLs with trailing slash', () => {
    expect(extractTokenCode('https://odin-worker.workers.dev/d/aB3kR9mQ/')).toBe('aB3kR9mQ');
  });
});

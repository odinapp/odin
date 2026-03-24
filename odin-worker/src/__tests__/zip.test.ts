import { describe, it, expect } from 'vitest';
import { zipFiles } from '../lib/zip';
import { unzipSync } from 'fflate';

describe('zipFiles', () => {
  it('returns a Uint8Array for a single file', () => {
    const result = zipFiles([{ name: 'hello.txt', data: new TextEncoder().encode('hello') }]);
    expect(result).toBeInstanceOf(Uint8Array);
    expect(result.length).toBeGreaterThan(0);
  });

  it('produces a valid zip containing all files', () => {
    const files = [
      { name: 'a.txt', data: new TextEncoder().encode('file a') },
      { name: 'b.txt', data: new TextEncoder().encode('file b') },
    ];
    const zipped = zipFiles(files);
    const unzipped = unzipSync(zipped);
    expect(Object.keys(unzipped)).toContain('a.txt');
    expect(Object.keys(unzipped)).toContain('b.txt');
    expect(new TextDecoder().decode(unzipped['a.txt'])).toBe('file a');
    expect(new TextDecoder().decode(unzipped['b.txt'])).toBe('file b');
  });
});

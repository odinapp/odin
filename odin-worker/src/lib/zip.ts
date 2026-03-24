import { zipSync } from 'fflate';

export interface FileEntry {
  name: string;
  data: Uint8Array;
}

export function zipFiles(files: FileEntry[]): Uint8Array {
  const input: Record<string, Uint8Array> = {};
  for (const file of files) {
    input[file.name] = file.data;
  }
  return zipSync(input);
}

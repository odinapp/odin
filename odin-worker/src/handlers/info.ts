import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';

export async function handleInfo(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);
  if (!token) {
    return jsonError(404, 'not found or expired');
  }

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  const preview = metadata.manifestPreview;
  if (preview && typeof preview === 'object') {
    const files = Array.isArray(preview.files) ? preview.files : [];
    const normalizedFiles = files
      .filter(item => item !== null && typeof item === 'object')
      .map(item => {
        const record = item as Record<string, unknown>;
        return {
          path: typeof record.path === 'string' ? record.path : null,
          size: typeof record.size === 'number' ? record.size : null,
        };
      })
      .filter(item => item.path !== null);

    return Response.json({
      basePath: null,
      files: normalizedFiles,
      totalFileSize: String(
        typeof preview.size === 'number' ? preview.size : metadata.originalTotalFileSize ?? metadata.size,
      ),
      fileCount: typeof preview.fileCount === 'number' ? preview.fileCount : normalizedFiles.length,
      isArchive: preview.zipped === true || metadata.isArchive === true,
    });
  }

  return Response.json({
    basePath: null,
    files: [{ path: metadata.filename }],
    totalFileSize: String(metadata.size),
    fileCount: metadata.fileCount ?? 1,
    isArchive: metadata.isArchive ?? metadata.filename.endsWith('.zip'),
    encryptedManifestPreview: metadata.encryptedManifestPreview ?? null,
  });
}

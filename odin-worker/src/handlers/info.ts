import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';

export async function handleInfo(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  return Response.json({
    basePath: null,
    files: [{ path: metadata.filename }],
    totalFileSize: String(metadata.size),
  });
}

import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { jsonError } from '../lib/response';

export async function handleRedirect(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const segments = url.pathname.split('/').filter(Boolean);
  const dIndex = segments.indexOf('d');
  const token = dIndex !== -1 ? segments[dIndex + 1] ?? '' : '';

  if (!token) {
    return jsonError(404, 'not found');
  }

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  const object = await env.R2_BUCKET.get(metadata.r2Key);
  if (!object) {
    return jsonError(404, 'not found or expired');
  }

  return new Response(object.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${metadata.filename}"`,
      'Filename': metadata.filename,
      'Content-Length': String(metadata.size),
    },
  });
}

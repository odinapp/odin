import type { Env } from '../types';
import { jsonError } from '../lib/response';

export async function handleRedirect(_req: Request, _env: Env): Promise<Response> {
  return jsonError(404, 'not found');
}

import type { Env } from './types';
import { handleUpload } from './handlers/upload';
import { handleInfo } from './handlers/info';
import { handleDownload } from './handlers/download';
import { handleConfig } from './handlers/config';
import { handleRedirect } from './handlers/redirect';
import { handleDelete } from './handlers/delete';
import { runCleanup } from './cron';
import { jsonError } from './lib/response';

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const { pathname } = url;
    const method = req.method;

    if (method === 'POST' && pathname === '/api/v1/file/upload/') {
      return handleUpload(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/file/info/') {
      return handleInfo(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/file/download/') {
      return handleDownload(req, env);
    }
    if (method === 'GET' && pathname === '/api/v1/config/') {
      return handleConfig(req, env);
    }
    if (method === 'GET' && pathname.startsWith('/d/')) {
      return handleRedirect(req, env);
    }
    if ((method === 'GET' || method === 'DELETE') && pathname.startsWith('/delete/')) {
      return handleDelete(req, env);
    }

    return jsonError(404, 'not found');
  },

  async scheduled(_event: ScheduledEvent, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(runCleanup(env));
  },
};

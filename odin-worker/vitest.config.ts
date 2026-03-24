import { defineWorkersConfig } from '@cloudflare/vitest-pool-workers/config';

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        wrangler: { configPath: './wrangler.toml' },
        miniflare: {
          kvNamespaces: ['KV_METADATA'],
          r2Buckets: ['R2_BUCKET'],
          bindings: {
            PUBLIC_URL: 'https://odin-worker.workers.dev',
          },
        },
      },
    },
  },
});

export default {
  async fetch(_request: Request, _env: unknown, _ctx: ExecutionContext): Promise<Response> {
    return new Response('Not implemented', { status: 501 });
  },
  async scheduled(_event: ScheduledEvent, _env: unknown, _ctx: ExecutionContext): Promise<void> {
    // TODO (Task 11): hourly cleanup cron
  },
};

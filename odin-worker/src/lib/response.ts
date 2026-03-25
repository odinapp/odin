export function jsonError(status: number, message: string): Response {
  return Response.json({ error: message }, { status });
}

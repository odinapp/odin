import type { Env } from '../types';

const CONFIG = {
  home: {
    title: 'Odin',
    primaryButtonText: 'Send files',
    secondaryButtonText: 'Receive files',
  },
  upload: {
    title: 'Uploading',
    description: 'Your files are being uploaded',
    backButtonText: 'Back',
    cancelDefaultText: 'Cancel',
    errorButtonText: 'Retry',
    errorDefaultText: 'Upload failed',
    successDefaultText: 'Upload complete',
  },
  token: {
    title: 'Receive files',
    description: 'Enter the token to download your files',
    textFieldHintText: 'Enter token',
    backButtonText: 'Back',
    primaryButtonText: 'Download',
  },
};

export function handleConfig(_req: Request, _env: Env): Response {
  return Response.json(CONFIG);
}

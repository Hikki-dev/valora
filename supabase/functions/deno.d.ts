/**
 * Temporary type definitions for the Deno namespace to satisfy the IDE's TypeScript compiler
 * when it fails to resolve the official Deno types in subdirectories.
 */
declare namespace Deno {
  export interface ServeOptions {
    port?: number;
    hostname?: string;
    onListen?: (params: { port: number; hostname: string }) => void;
  }

  export function serve(
    handler: (request: Request, info: any) => Response | Promise<Response>,
    options?: ServeOptions
  ): void;

  export function serve(
    options: ServeOptions,
    handler: (request: Request, info: any) => Response | Promise<Response>
  ): void;

  export const env: {
    get(key: string): string | undefined;
    set(key: string, value: string): void;
    delete(key: string): void;
    toObject(): { [key: string]: string };
  };
}

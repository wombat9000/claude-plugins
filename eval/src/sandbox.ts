import { execSync } from 'child_process';
import { homedir } from 'os';

interface SandboxOptions {
  workingDir: string;
  timeout?: number;
}

export function invokeInSandbox(
  input: string,
  opts: SandboxOptions
): { output: string; error?: string } {
  const { workingDir, timeout = 120_000 } = opts;

  const claudeAuth = `${homedir()}/.claude`;

  const dockerCmd = [
    'docker run --rm',
    '--memory=512m',
    '--cpus=1',
    `-v "${workingDir}:/workspace"`,
    `-v "${claudeAuth}:/host-claude:ro"`,
    'claude-eval-sandbox',
    'claude',
    '--print',
    '--dangerously-skip-permissions',
    '-p',
    JSON.stringify(input),
  ].join(' ');

  try {
    const output = execSync(dockerCmd, {
      encoding: 'utf-8',
      timeout,
      maxBuffer: 10 * 1024 * 1024,
    });
    return { output };
  } catch (error) {
    const execError = error as { stdout?: string; stderr?: string; message: string };
    return {
      output: execError.stdout ?? '',
      error: execError.stderr ?? execError.message,
    };
  }
}
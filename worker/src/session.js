import { spawn } from 'child_process';

const PROMPT_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutos por prompt

/**
 * Calls the local AI CLI passing the prompt via stdin.
 * Uses --continue on turns 2+ so the CLI maintains the session context itself.
 *
 * Configured via env vars:
 *   AI_CLI_COMMAND  — executable name (default: "claude")
 *   AI_CLI_ARGS     — extra args added to every call (default: "--no-markdown")
 */
async function callCli(prompt, continueSession, logger) {
  const command = process.env.AI_CLI_COMMAND || 'claude';
  const extraArgs = (process.env.AI_CLI_ARGS || '--no-markdown').split(/\s+/).filter(Boolean);

  const args = ['-p', ...extraArgs];
  if (continueSession) args.push('--continue');

  logger.debug(`CLI: ${command} ${args.join(' ')}`);

  return new Promise((resolve, reject) => {
    const proc = spawn(command, args, {
      stdio: ['pipe', 'pipe', 'pipe'],
      shell: false,
    });

    let output = '';
    let errorOutput = '';

    proc.stdout.on('data', (chunk) => { output += chunk.toString(); });
    proc.stderr.on('data', (chunk) => { errorOutput += chunk.toString(); });

    proc.stdin.write(prompt, 'utf8');
    proc.stdin.end();

    const timeout = setTimeout(() => {
      proc.kill('SIGTERM');
      reject(new Error(`CLI timeout después de ${PROMPT_TIMEOUT_MS / 1000}s`));
    }, PROMPT_TIMEOUT_MS);

    proc.on('close', (code) => {
      clearTimeout(timeout);
      if (code === 0 && output.trim().length > 0) {
        resolve(output.trim());
      } else if (code === 0 && output.trim().length === 0) {
        reject(new Error(`CLI salió con código 0 pero sin output. stderr: ${errorOutput.slice(0, 500)}`));
      } else {
        reject(new Error(
          `CLI salió con código ${code}. stderr: ${errorOutput.slice(0, 500) || '(vacío)'}`,
        ));
      }
    });

    proc.on('error', (err) => {
      clearTimeout(timeout);
      reject(new Error(`No se pudo ejecutar "${command}": ${err.message}`));
    });
  });
}

/**
 * Runs a multi-turn conversation using the CLI's native session continuity.
 * Prompt 1 starts a new session; subsequent prompts use --continue.
 *
 * @param {string[]} prompts  Ordered array of prompt strings
 * @param {Object}   logger   Winston logger instance
 * @returns {Promise<string[]>}  All responses in order
 */
export async function runSession(prompts, logger) {
  if (!prompts || prompts.length === 0) {
    throw new Error('No hay prompts para ejecutar');
  }

  const responses = [];

  for (let i = 0; i < prompts.length; i++) {
    const promptNum = i + 1;
    const continueSession = i > 0;

    logger.info(`Ejecutando Prompt ${promptNum}/${prompts.length}${continueSession ? ' (--continue)' : ' (nueva sesión)'}...`);

    const response = await callCli(prompts[i], continueSession, logger);
    responses.push(response);

    logger.info(`Prompt ${promptNum}/${prompts.length} completado (${response.length} caracteres)`);
  }

  return responses;
}

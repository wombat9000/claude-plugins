import fs from 'fs/promises';
import path from 'path';
import YAML from 'yaml';
import { EvalConfig, TestResult, TestContext, SetupStep } from './types.js';
import { scorers } from './scorers/index.js';
import { invokeInSandbox } from './sandbox.js';

export async function runEval(pluginName: string): Promise<void> {
  console.log(`Running eval for plugin: ${pluginName}\n`);

  // Load eval.yaml config
  const configPath = path.join(
  process.cwd(),  // = /repo/eval
  '..',           // = /repo
  'plugins',
  pluginName,     // = config-wizard
  'evals',
  'eval.yaml'     // = /repo/plugins/config-wizard/evals/eval.yaml
);
  const configContent = await fs.readFile(configPath, 'utf-8');
  const config: EvalConfig = YAML.parse(configContent);

  if (config.plugin !== pluginName) {
    throw new Error(`Config mismatch: expected ${pluginName}, got ${config.plugin}`);
  }

  const results: TestResult[] = [];

  // Run each test case
  for (const testCase of config.testCases) {
    console.log(`\n📝 Test: ${testCase.name}`);
    console.log(`   Input: ${testCase.input}`);

    // Setup test environment
    const workingDir = await setupTestEnvironment(testCase.name);
    const context: TestContext = { workingDir };

    // Run setup steps if any
    if (testCase.setup) {
      for (const step of testCase.setup) {
        await runSetupStep(step, workingDir);
      }
    }

    // Execute the skill/plugin with testCase.input
    console.log(`   🚀 Invoking Claude Code...`);
    const result = invokeInSandbox(testCase.input, { workingDir });

    // Add output to context for scorers
    context.output = result.output;

    if (result.error) {
      console.log(`   ⚠️  Execution error: ${result.error}`);
    }

    // Run checks
    const checkResults = [];
    let totalScore = 0;
    let maxScore = 0;

    for (const check of testCase.checks) {
      const scorer = scorers[check.type];
      if (!scorer) {
        throw new Error(`Unknown check type: ${check.type}`);
      }

      const result = await scorer.score(check, context);
      checkResults.push(result);
      totalScore += result.score;
      maxScore += result.maxScore;

      const status = result.passed ? '✅' : '❌';
      console.log(`   ${status} ${check.type}: ${result.score}/${result.maxScore}`);
      if (result.details) {
        console.log(`      ${result.details}`);
      }
    }

    const testResult: TestResult = {
      testCase: testCase.name,
      passed: totalScore === maxScore,
      score: totalScore,
      maxScore,
      checkResults,
    };

    results.push(testResult);
  }

  // Print summary
  printSummary(results);
}

async function setupTestEnvironment(testName: string): Promise<string> {
  const tempDir = path.join(process.cwd(), '.eval-temp', testName);
  await fs.mkdir(tempDir, { recursive: true });
  return tempDir;
}

async function runSetupStep(step: SetupStep, workingDir: string): Promise<void> {
  if (step.type === 'create-file' && step.path && step.content) {
    const filePath = path.join(workingDir, step.path);
    await fs.mkdir(path.dirname(filePath), { recursive: true });
    await fs.writeFile(filePath, step.content);
  } else if (step.type === 'run-command' && step.command) {
    // TODO: Execute command in workingDir
    console.log(`   Setup: ${step.command}`);
  }
}

function printSummary(results: TestResult[]): void {
  console.log('\n' + '='.repeat(50));
  console.log('SUMMARY');
  console.log('='.repeat(50));

  const totalTests = results.length;
  const passedTests = results.filter((r) => r.passed).length;
  const totalScore = results.reduce((sum, r) => sum + r.score, 0);
  const maxScore = results.reduce((sum, r) => sum + r.maxScore, 0);

  console.log(`Tests passed: ${passedTests}/${totalTests}`);
  console.log(
    `Total score: ${totalScore}/${maxScore} (${((totalScore / maxScore) * 100).toFixed(1)}%)`
  );
}

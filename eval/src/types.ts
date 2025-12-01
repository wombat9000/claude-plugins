export interface EvalConfig {
  plugin: string;
  description?: string;
  testCases: TestCase[];
}

export interface TestCase {
  name: string;
  input: string;
  setup?: SetupStep[];
  checks: Check[];
}

export interface SetupStep {
  type: 'create-file' | 'run-command';
  path?: string;
  content?: string;
  command?: string;
}

export interface Check {
  type: 'file-exists' | 'contains-pattern' | 'llm-judge';
  path?: string;
  pattern?: string;
  prompt?: string;
  weight?: number;
  files?: string[];
}

export interface TestResult {
  testCase: string;
  passed: boolean;
  score: number;
  maxScore: number;
  checkResults: CheckResult[];
}

export interface CheckResult {
  type: string;
  passed: boolean;
  score: number;
  maxScore: number;
  details?: string;
}

export interface Scorer {
  type: string;
  score(check: Check, context: TestContext): Promise<CheckResult>;
}

export interface TestContext {
  workingDir: string;
  output?: string;
}

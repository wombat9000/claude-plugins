import fs from 'fs/promises';
import path from 'path';
import { Scorer, Check, CheckResult, TestContext } from '../types.js';

export const containsPatternScorer: Scorer = {
  type: 'contains-pattern',

  async score(check: Check, context: TestContext): Promise<CheckResult> {
    if (!check.path || !check.pattern) {
      throw new Error('contains-pattern check requires path and pattern');
    }

    const filePath = path.join(context.workingDir, check.path);
    let content: string;

    try {
      content = await fs.readFile(filePath, 'utf-8');
    } catch {
      return {
        type: 'contains-pattern',
        passed: false,
        score: 0,
        maxScore: 1,
        details: `File ${check.path} not found`,
      };
    }

    const regex = new RegExp(check.pattern);
    const matches = regex.test(content);

    return {
      type: 'contains-pattern',
      passed: matches,
      score: matches ? 1 : 0,
      maxScore: 1,
      details: matches
        ? `Pattern "${check.pattern}" found in ${check.path}`
        : `Pattern "${check.pattern}" not found in ${check.path}`,
    };
  },
};

import fs from 'fs/promises';
import path from 'path';
import { Scorer, Check, CheckResult, TestContext } from '../types.js';

export const fileExistsScorer: Scorer = {
  type: 'file-exists',

  async score(check: Check, context: TestContext): Promise<CheckResult> {
    if (!check.path) {
      throw new Error('file-exists check requires a path');
    }

    const filePath = path.join(context.workingDir, check.path);
    let exists = false;

    try {
      await fs.access(filePath);
      exists = true;
    } catch {
      exists = false;
    }

    return {
      type: 'file-exists',
      passed: exists,
      score: exists ? 1 : 0,
      maxScore: 1,
      details: exists ? `File ${check.path} exists` : `File ${check.path} not found`,
    };
  },
};

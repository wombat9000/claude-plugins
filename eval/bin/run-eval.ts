#!/usr/bin/env node

import { runEval } from '../src/runner.js';

const pluginName = process.argv[2];

if (!pluginName) {
  console.error('Usage: tsx bin/run-eval.ts <plugin-name>');
  process.exit(1);
}

runEval(pluginName).catch((error) => {
  console.error('Eval failed:', error);
  process.exit(1);
});

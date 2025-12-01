import { Scorer } from '../types.js';
import { fileExistsScorer } from './file-exists.js';
import { containsPatternScorer } from './contains-pattern.js';
import { llmJudgeScorer } from './llm-judge.js';

export const scorers: Record<string, Scorer> = {
  'file-exists': fileExistsScorer,
  'contains-pattern': containsPatternScorer,
  'llm-judge': llmJudgeScorer,
};

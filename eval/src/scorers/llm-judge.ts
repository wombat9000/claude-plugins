import { GoogleGenerativeAI } from '@google/generative-ai';
import { Scorer, Check, CheckResult, TestContext } from '../types.js';
import { readFile } from 'fs/promises';
import { join } from 'path';

let model: ReturnType<GoogleGenerativeAI['getGenerativeModel']> | null = null;

function getModel() {
  if (!model) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is required');
    }
    const genAI = new GoogleGenerativeAI(apiKey);
    model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });
  }
  return model;
}

export const llmJudgeScorer: Scorer = {
  type: 'llm-judge',

  async score(check: Check, context: TestContext): Promise<CheckResult> {
    if (!check.prompt) {
      throw new Error('llm-judge check requires a prompt');
    }

    const weight = check.weight ?? 1;

    // Gather file contents if specified
    let fileContents = '';
    if (check.files?.length) {
      for (const file of check.files) {
        try {
          const content = await readFile(join(context.workingDir, file), 'utf-8');
          fileContents += `\n--- ${file} ---\n${content}\n`;
        } catch {
          fileContents += `\n--- ${file} ---\n[FILE NOT FOUND]\n`;
        }
      }
    }

    const evaluationPrompt = `
You are evaluating the output of a Claude Code skill.

${fileContents ? `Generated files:\n${fileContents}` : ''}
${context.output ? `Command output:\n${context.output}` : ''}

Criteria: ${check.prompt}

Respond ONLY with JSON:
{"passed": boolean, "confidence": 0.0-1.0, "reasoning": "one sentence"}
`.trim();

    try {
      const result = await getModel().generateContent(evaluationPrompt);
      const text = result.response.text();
      
      const jsonMatch = text.match(/\{[\s\S]*?\}/);
      if (!jsonMatch) throw new Error('No JSON in response');
      
      const { passed, confidence, reasoning } = JSON.parse(jsonMatch[0]);

      return {
        type: 'llm-judge',
        passed,
        score: passed ? weight * confidence : 0,
        maxScore: weight,
        details: reasoning,
      };
    } catch (error) {
      return {
        type: 'llm-judge',
        passed: false,
        score: 0,
        maxScore: weight,
        details: `LLM evaluation failed: ${error}`,
      };
    }
  },
};
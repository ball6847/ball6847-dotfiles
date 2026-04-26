#!/usr/bin/env -S deno run --allow-read --allow-write

import { Command } from "@cliffy/command";
import { err, ok, Result } from "neverthrow";

const SKILLS_DIR = `${Deno.env.get("HOME")}/.agents/skills`;
const FRONTMATTER_RE = /^---\r?\n([\s\S]*?)\r?\n---/;
const BARE_DESC_RE = /^description\s*:/;
const GUARDED_DESC_RE = /^_description_?\s*:/;

interface Violation {
  file: string;
  line: number;
  content: string;
}

async function getSkillFiles(): Promise<string[]> {
  const files: string[] = [];
  try {
    for await (const entry of Deno.readDir(SKILLS_DIR)) {
      if (entry.isDirectory) {
        const skillFile = `${SKILLS_DIR}/${entry.name}/SKILL.md`;
        try {
          const stat = await Deno.stat(skillFile);
          if (stat.isFile) {
            files.push(skillFile);
          }
        } catch (e) {
          if (!(e instanceof Deno.errors.NotFound)) {
            console.warn(
              `⚠ Warning: Could not stat ${skillFile}: ${
                e instanceof Error ? e.message : String(e)
              }`,
            );
          }
        }
      }
    }
  } catch (e) {
    if (e instanceof Deno.errors.NotFound) {
      console.error(`❌ Error: Skills directory not found: ${SKILLS_DIR}`);
      Deno.exit(1);
    }
    console.error(
      `❌ Error reading skills directory: ${
        e instanceof Error ? e.message : String(e)
      }`,
    );
    Deno.exit(1);
  }
  return files;
}

function parseFrontmatter(content: string): string | null {
  const m = content.match(FRONTMATTER_RE);
  return m ? m[1] : null;
}

function findViolations(content: string, filePath: string): Violation[] {
  const fm = parseFrontmatter(content);
  if (!fm) return [];

  const violations: Violation[] = [];
  const lines = fm.split("\n");

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (BARE_DESC_RE.test(line)) {
      violations.push({
        file: filePath,
        line: i + 2,
        content: lines[i],
      });
    }
  }

  return violations;
}

function cleanDescription(content: string): Result<string, string> {
  const m = content.match(FRONTMATTER_RE);
  if (!m) return err("No frontmatter found");

  const frontmatter = m[1];
  const lines = frontmatter.split("\n");
  let changed = false;

  const cleanedLines = lines.map((line) => {
    if (BARE_DESC_RE.test(line)) {
      changed = true;
      return line.replace(/^description/, `_description`);
    }
    return line;
  });

  if (!changed) return ok(content);

  const cleanedFrontmatter = cleanedLines.join("\n");
  const fullMatch = m[0];
  const result = content.replace(fullMatch, `---\n${cleanedFrontmatter}\n---`);
  return ok(result);
}

function restoreDescription(content: string): Result<string, string> {
  const m = content.match(FRONTMATTER_RE);
  if (!m) return err("No frontmatter found");

  const frontmatter = m[1];
  const lines = frontmatter.split("\n");
  let changed = false;

  const restoredLines = lines.map((line) => {
    if (GUARDED_DESC_RE.test(line)) {
      changed = true;
      return line.replace(/^_description_?/, `description`);
    }
    return line;
  });

  if (!changed) return ok(content);

  const restoredFrontmatter = restoredLines.join("\n");
  const fullMatch = m[0];
  const result = content.replace(fullMatch, `---\n${restoredFrontmatter}\n---`);
  return ok(result);
}

async function check(): Promise<number> {
  const files = await getSkillFiles();
  const allViolations: Violation[] = [];

  for (const file of files) {
    try {
      const content = await Deno.readTextFile(file);
      const violations = findViolations(content, file);
      allViolations.push(...violations);
    } catch (e) {
      console.warn(
        `⚠ Warning: Could not read ${file}: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
    }
  }

  if (allViolations.length === 0) {
    console.log("✓ No bare 'description:' fields found.");
    return 0;
  }

  for (const v of allViolations) {
    console.log(`✗ ${v.file}:${v.line} → ${v.content.trim()}`);
  }
  console.log(`\n${allViolations.length} violation(s) found.`);
  return allViolations.length;
}

async function clean(): Promise<number> {
  const files = await getSkillFiles();
  let changed = 0;

  for (const file of files) {
    try {
      const content = await Deno.readTextFile(file);
      const result = cleanDescription(content);

      if (result.isErr()) {
        console.log(`⚠ ${file}: ${result.error}`);
        continue;
      }

      if (result.value !== content) {
        try {
          await Deno.writeTextFile(file, result.value);
          console.log(`✓ Fixed: ${file}`);
          changed++;
        } catch (e) {
          console.warn(
            `⚠ Warning: Could not write ${file}: ${
              e instanceof Error ? e.message : String(e)
            }`,
          );
        }
      }
    } catch (e) {
      console.warn(
        `⚠ Warning: Could not read ${file}: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
    }
  }

  console.log(`\nFixed ${changed} file(s).`);
  return changed;
}

async function restore(): Promise<number> {
  const files = await getSkillFiles();
  let changed = 0;

  for (const file of files) {
    try {
      const content = await Deno.readTextFile(file);
      const result = restoreDescription(content);

      if (result.isErr()) {
        console.log(`⚠ ${file}: ${result.error}`);
        continue;
      }

      if (result.value !== content) {
        try {
          await Deno.writeTextFile(file, result.value);
          console.log(`✓ Restored: ${file}`);
          changed++;
        } catch (e) {
          console.warn(
            `⚠ Warning: Could not write ${file}: ${
              e instanceof Error ? e.message : String(e)
            }`,
          );
        }
      }
    } catch (e) {
      console.warn(
        `⚠ Warning: Could not read ${file}: ${
          e instanceof Error ? e.message : String(e)
        }`,
      );
    }
  }

  console.log(`\nRestored ${changed} file(s).`);
  return changed;
}

await new Command()
  .name("lean-skills")
  .description("Manage description fields in skill frontmatter")
  .command("check", "Check for bare 'description:' fields")
  .action(async () => {
    const violations = await check();
    Deno.exit(violations > 0 ? 1 : 0);
  })
  .command("clean")
  .description("Replace bare 'description:' with '_description:'")
  .action(async () => {
    await clean();
  })
  .command("restore")
  .description("Restore _description: back to description:")
  .action(async () => {
    await restore();
  })
  .parse(Deno.args);

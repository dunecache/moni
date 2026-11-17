#!/usr/bin/env node
// Lightweight structural validation for the moni Dart source.
// This is not a substitute for `dart analyze`; it catches broken imports,
// unbalanced delimiters and raw color literals without a Dart SDK.
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join, dirname, resolve, relative } from 'node:path';

const root = resolve(process.argv[2] ?? '.');
const lib = join(root, 'lib');
const test = join(root, 'test');

function walk(dir) {
  if (!existsSync(dir)) return [];
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? walk(path) : path.endsWith('.dart') ? [path] : [];
  });
}

const files = [...walk(lib), ...walk(test)];
let failures = 0;

function stripStringsAndComments(source) {
  let out = '';
  let i = 0;
  let inString = false;
  let triple = false;
  let raw = false;
  let inLineComment = false;
  let inBlockComment = 0;
  while (i < source.length) {
    const c = source[i];
    const n = source[i + 1];
    if (inLineComment) {
      if (c === '\n') { inLineComment = false; out += '\n'; }
      i++; continue;
    }
    if (inBlockComment > 0) {
      if (c === '/' && n === '*') { inBlockComment++; i += 2; continue; }
      if (c === '*' && n === '/') { inBlockComment--; i += 2; continue; }
      i++; continue;
    }
    if (inString) {
      if (triple && c === "'" && n === "'" && source[i + 2] === "'") {
        inString = false; triple = false; i += 3; continue;
      }
      if (!triple && c === "'") { inString = false; if (raw && source[i - 1] === 'r') raw = false; i++; continue; }
      if (c === '\\' && !raw) { i += 2; continue; }
      i++; continue;
    }
    if (c === '/' && n === '/') { inLineComment = true; i += 2; continue; }
    if (c === '/' && n === '*') { inBlockComment = 1; i += 2; continue; }
    if (c === "'") {
      inString = true;
      triple = source[i + 1] === "'" && source[i + 2] === "'";
      raw = i > 0 && source[i - 1] === 'r';
      i += triple ? 3 : 1;
      continue;
    }
    out += c;
    i++;
  }
  return out;
}

function balanced(code, path) {
  const pairs = { ')': '(', ']': '[', '}': '{' };
  const stack = [];
  for (const c of code) {
    if (c === '(' || c === '[' || c === '{') stack.push(c);
    else if (pairs[c]) {
      if (stack.pop() !== pairs[c]) {
        console.error(`FAIL ${relative(root, path)}: unbalanced '${c}'`);
        failures++;
        return;
      }
    }
  }
  if (stack.length) {
    console.error(`FAIL ${relative(root, path)}: unclosed '${stack[stack.length - 1]}'`);
    failures++;
  }
}

function checkImports(source, path) {
  const pattern = /import\s+['"]([^'"]+)['"]\s*;/g;
  let match;
  while ((match = pattern.exec(source))) {
    const spec = match[1];
    let target;
    if (spec.startsWith('package:moni/')) {
      target = join(lib, spec.slice('package:moni/'.length));
    } else if (spec.startsWith('.')) {
      target = resolve(dirname(path), spec);
    } else {
      continue;
    }
    if (!existsSync(target)) {
      console.error(`FAIL ${relative(root, path)}: unresolved import '${spec}'`);
      failures++;
    }
  }
}

for (const file of files) {
  const source = readFileSync(file, 'utf8');
  checkImports(source, file);
  balanced(stripStringsAndComments(source), file);
  const isTokenFile = file.endsWith('kanso_tokens.dart');
  const isTest = file.startsWith(test);
  if (!isTokenFile && !isTest && /0xFF[0-9A-Fa-f]{6}|#[0-9A-Fa-f]{6}\b/.test(source)) {
    console.error(`FAIL ${relative(root, file)}: raw color literal outside token adapter`);
    failures++;
  }
}

console.log(`Checked ${files.length} Dart files.`);
if (failures) {
  console.error(`${failures} structural problem(s) found.`);
  process.exit(1);
}
console.log('Structure OK.');

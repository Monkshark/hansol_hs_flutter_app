#!/usr/bin/env node
/**
 * docs/build_viewer.js
 *
 * MD 파일을 모두 읽어 index.html에 인라인으로 포함시키는 빌드 스크립트.
 * 사용법: node docs/build_viewer.js
 * 결과:  docs/index.html (서버 없이 브라우저에서 바로 열 수 있음)
 */
const fs = require('fs');
const path = require('path');

const docsDir = path.resolve(__dirname);
const outFile = path.join(docsDir, 'index.html');

const mdFiles = {};
function walk(dir, prefix) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
    if (entry.isDirectory()) {
      walk(path.join(dir, entry.name), prefix ? prefix + '/' + entry.name : entry.name);
    } else if (entry.name.endsWith('.md')) {
      const relPath = prefix ? prefix + '/' + entry.name : entry.name;
      mdFiles[relPath] = fs.readFileSync(path.join(dir, entry.name), 'utf8');
    }
  }
}
walk(docsDir, '');

const fileCount = Object.keys(mdFiles).length;
const jsonData = JSON.stringify(mdFiles);

const templateFile = path.join(docsDir, '_viewer_template.html');
const template = fs.readFileSync(templateFile, 'utf8');
const html = template.replace('/*__MD_DATA__*/', 'const MD_DATA = ' + jsonData + ';');

fs.writeFileSync(outFile, html, 'utf8');
const sizeKB = (Buffer.byteLength(html) / 1024).toFixed(1);
console.log('Built ' + outFile + ' (' + fileCount + ' docs, ' + sizeKB + ' KB)');

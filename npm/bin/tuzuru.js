#!/usr/bin/env node
/*
 * Wrapper executable for Tuzuru binary installed via npm.
 * - Determines the installed vendor directory
 * - Sets TUZURU_RESOURCES for bundle/resources discovery
 * - Spawns the native binary with passed args
 */

const { spawn } = require('node:child_process');
const { existsSync, readdirSync } = require('node:fs');
const { join } = require('node:path');

function fail(msg) {
  console.error(msg);
  process.exit(1);
}

const platform = process.platform; // 'darwin' | 'linux'
const arch = process.arch; // 'x64' | 'arm64'

if (!['darwin', 'linux'].includes(platform)) {
  fail(`Unsupported platform: ${platform}`);
}
if (!['x64', 'arm64'].includes(arch)) {
  fail(`Unsupported architecture: ${arch}`);
}

const pkgRoot = join(__dirname, '..');
const vendorDir = join(pkgRoot, 'vendor', `${platform}-${arch}`);
const binPath = join(vendorDir, 'tuzuru');

if (!existsSync(binPath)) {
  fail('tuzuru binary is not installed. Try reinstalling the package.');
}

// Discover bundled resources next to the binary
let resourcesPath = null;
try {
  const entries = readdirSync(vendorDir, { withFileTypes: true });
  for (const ent of entries) {
    if (ent.isDirectory() && (ent.name.endsWith('.bundle') || ent.name.endsWith('.resources'))) {
      resourcesPath = join(vendorDir);
      break;
    }
  }
} catch {}

const env = { ...process.env };
if (resourcesPath) {
  env.TUZURU_RESOURCES = resourcesPath;
}

const args = process.argv.slice(2);
const child = spawn(binPath, args, { stdio: 'inherit', env });
child.on('exit', (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exit(code ?? 0);
  }
});


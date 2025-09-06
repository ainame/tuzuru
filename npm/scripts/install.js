#!/usr/bin/env node
/*
 * Postinstall script to download and extract the correct Tuzuru prebuilt binary
 * matching the npm package version.
 *
 * It resolves:
 *   - platform: darwin|linux
 *   - arch: x64|arm64
 * and fetches from GitHub Releases:
 *   https://api.github.com/repos/ainame/Tuzuru/releases/tags/<version>
 * to find the asset name:
 *   tuzuru-<version>-macos-universal.tar.gz
 *   tuzuru-<version>-linux-x86_64.tar.gz
 *   tuzuru-<version>-linux-aarch64.tar.gz
 */

const https = require('node:https');
const { execSync } = require('node:child_process');
const { mkdirSync, existsSync, createWriteStream, rmSync } = require('node:fs');
const { join } = require('node:path');

function log(msg) {
  console.log(`[tuzuru-npm] ${msg}`);
}
function fail(msg) {
  console.error(`[tuzuru-npm] ${msg}`);
  process.exit(1);
}

const pkg = require('../../package.json');
const version = (pkg.version || '').trim();
if (!version || version === '0.0.0') {
  log('Package version is 0.0.0; attempting to install latest release via GitHub API');
}

const platform = process.platform; // 'darwin' | 'linux'
const arch = process.arch; // 'x64' | 'arm64'
if (!['darwin', 'linux'].includes(platform)) fail(`Unsupported platform: ${platform}`);
if (!['x64', 'arm64'].includes(arch)) fail(`Unsupported architecture: ${arch}`);

const suffix = platform === 'darwin'
  ? 'macos-universal.tar.gz'
  : (arch === 'x64' ? 'linux-x86_64.tar.gz' : 'linux-aarch64.tar.gz');

const apiUrl = version && version !== '0.0.0'
  ? `https://api.github.com/repos/ainame/Tuzuru/releases/tags/${encodeURIComponent(version)}`
  : `https://api.github.com/repos/ainame/Tuzuru/releases/latest`;

const ua = 'tuzuru-npm-installer (+https://github.com/ainame/Tuzuru)';

function httpGetJson(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': ua, 'Accept': 'application/vnd.github+json' } }, res => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        res.resume();
        return;
      }
      let data = '';
      res.setEncoding('utf8');
      res.on('data', chunk => (data += chunk));
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function httpDownload(url, destPath) {
  return new Promise((resolve, reject) => {
    function handleRedirect(url, maxRedirects = 5) {
      if (maxRedirects === 0) {
        reject(new Error('Too many redirects'));
        return;
      }
      
      const file = createWriteStream(destPath);
      
      https.get(url, { headers: { 'User-Agent': ua } }, res => {
        if (res.statusCode === 301 || res.statusCode === 302) {
          file.close(() => {});
          const location = res.headers.location;
          if (!location) {
            reject(new Error(`Redirect response missing location header`));
            return;
          }
          log(`Following redirect to ${location}`);
          handleRedirect(location, maxRedirects - 1);
          return;
        }
        
        if (res.statusCode !== 200) {
          file.close(() => {});
          reject(new Error(`HTTP ${res.statusCode} for ${url}`));
          res.resume();
          return;
        }
        
        res.pipe(file);
        file.on('finish', () => file.close(resolve));
        file.on('error', err => {
          file.close(() => {});
          try { rmSync(destPath, { force: true }); } catch {}
          reject(err);
        });
      }).on('error', err => {
        file.close(() => {});
        try { rmSync(destPath, { force: true }); } catch {}
        reject(err);
      });
    }
    
    handleRedirect(url);
  });
}

(async () => {
  try {
    const json = await httpGetJson(apiUrl);
    const assets = json.assets || [];
    const asset = assets.find(a => typeof a.name === 'string' && a.name.endsWith(suffix));
    if (!asset) {
      const assetList = assets.map(a => a.name).join(', ');
      fail(`No matching asset found for suffix ${suffix}. Available: ${assetList}`);
    }

    const downloadUrl = asset.browser_download_url;
    const root = join(__dirname, '..');
    const outDir = join(root, 'vendor', `${platform}-${arch}`);
    const tarPath = join(outDir, 'tuzuru.tar.gz');
    if (!existsSync(outDir)) mkdirSync(outDir, { recursive: true });

    log(`Downloading ${downloadUrl}`);
    await httpDownload(downloadUrl, tarPath);

    // Extract using system tar
    log('Extracting archive');
    execSync(`tar -xzf "${tarPath}" -C "${outDir}"`, { stdio: 'inherit' });

    // Ensure binary is executable
    execSync(`chmod +x "${join(outDir, 'tuzuru')}"`);

    // Cleanup
    rmSync(tarPath, { force: true });
    log('Installation completed');
  } catch (err) {
    fail(`Install failed: ${err.message}`);
  }
})();


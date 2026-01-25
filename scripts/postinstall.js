#!/usr/bin/env node
/**
 * Post-install script for doyaken
 *
 * Copies prompts, templates, and config to ~/.doyaken/
 * This allows the CLI to work from any directory.
 */

const fs = require('fs');
const path = require('path');
const os = require('os');

const DOYAKEN_HOME = process.env.DOYAKEN_HOME || path.join(os.homedir(), '.doyaken');

const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  blue: '\x1b[34m',
  yellow: '\x1b[33m',
};

function log(msg) {
  console.log(`${colors.blue}[doyaken]${colors.reset} ${msg}`);
}

function success(msg) {
  console.log(`${colors.green}[doyaken]${colors.reset} ${msg}`);
}

function warn(msg) {
  console.log(`${colors.yellow}[doyaken]${colors.reset} ${msg}`);
}

function copyDir(src, dest) {
  if (!fs.existsSync(src)) {
    return;
  }

  fs.mkdirSync(dest, { recursive: true });

  const entries = fs.readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);

    if (entry.isDirectory()) {
      copyDir(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

function main() {
  log(`Setting up doyaken at ${DOYAKEN_HOME}`);

  // Create directories
  const dirs = ['prompts', 'templates', 'config', 'projects', 'lib'];
  for (const dir of dirs) {
    fs.mkdirSync(path.join(DOYAKEN_HOME, dir), { recursive: true });
  }

  // Get package root (where we're installed)
  const packageRoot = path.resolve(__dirname, '..');

  // Copy prompts (from agent/prompts if exists, otherwise prompts/)
  const promptsSrc = fs.existsSync(path.join(packageRoot, 'agent', 'prompts'))
    ? path.join(packageRoot, 'agent', 'prompts')
    : path.join(packageRoot, 'prompts');

  if (fs.existsSync(promptsSrc)) {
    copyDir(promptsSrc, path.join(DOYAKEN_HOME, 'prompts'));
    success('Copied prompts');
  }

  // Copy templates
  const templatesSrc = path.join(packageRoot, 'templates');
  if (fs.existsSync(templatesSrc)) {
    copyDir(templatesSrc, path.join(DOYAKEN_HOME, 'templates'));
    success('Copied templates');
  }

  // Copy config
  const configSrc = path.join(packageRoot, 'config');
  if (fs.existsSync(configSrc)) {
    copyDir(configSrc, path.join(DOYAKEN_HOME, 'config'));
    success('Copied config');
  }

  // Copy lib files
  const libSrc = path.join(packageRoot, 'lib');
  if (fs.existsSync(libSrc)) {
    copyDir(libSrc, path.join(DOYAKEN_HOME, 'lib'));
    // Make scripts executable
    const libFiles = fs.readdirSync(path.join(DOYAKEN_HOME, 'lib'));
    for (const file of libFiles) {
      if (file.endsWith('.sh')) {
        fs.chmodSync(path.join(DOYAKEN_HOME, 'lib', file), '755');
      }
    }
    success('Copied lib');
  }

  // Create VERSION file
  const pkg = require(path.join(packageRoot, 'package.json'));
  fs.writeFileSync(path.join(DOYAKEN_HOME, 'VERSION'), pkg.version);

  // Initialize empty registry if not exists
  const registryPath = path.join(DOYAKEN_HOME, 'projects', 'registry.yaml');
  if (!fs.existsSync(registryPath)) {
    fs.writeFileSync(registryPath, `# Doyaken Project Registry
version: 1
projects: []
aliases: {}
`);
    success('Created project registry');
  }

  success(`Doyaken ${pkg.version} installed successfully!`);
  console.log('');
  console.log('Quick start:');
  console.log('  cd /path/to/your/project');
  console.log('  dk init                    # Initialize project');
  console.log('  dk tasks new "My task"     # Create a task');
  console.log('  dk run 1                   # Run 1 task');
  console.log('');
}

try {
  main();
} catch (err) {
  warn(`Post-install warning: ${err.message}`);
  // Don't fail the install on post-install errors
}

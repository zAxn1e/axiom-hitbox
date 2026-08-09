import * as fs from 'fs';
import * as path from 'path';

// Define project root and output paths
const ROOT_DIR = path.resolve(__dirname, '..');
const DOCS_DIR = path.join(ROOT_DIR, 'docs');
const PUBLIC_DIR = path.join(DOCS_DIR, 'public');

// Ensure output public directory exists
if (!fs.existsSync(PUBLIC_DIR)) {
  fs.mkdirSync(PUBLIC_DIR, { recursive: true });
}

// 1. Read package metadata for canonical version and description
const pkgPath = path.join(ROOT_DIR, 'package.json');
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));

const VERSION = pkg.version || '1.4.0';
const PROJECT_NAME = 'Axiom Hitbox Framework';
const PROJECT_DESC = pkg.description || 'Server-authoritative, low-overhead Roblox spatial hitbox and synchronization framework';
const BASE_URL = 'https://zAxn1e.github.io/axiom-hitbox';

// Section & File Hierarchy matching VitePress config
interface DocPage {
  title: string;
  file: string; // Relative to docs/
  link: string; // Relative web route
  description: string;
}

interface DocSection {
  sectionTitle: string;
  items: DocPage[];
}

const SECTIONS: DocSection[] = [
  {
    sectionTitle: 'Getting Started',
    items: [
      {
        title: 'Installation',
        file: 'getting-started/installation.md',
        link: '/getting-started/installation',
        description: 'Installation options via Creator Store, GitHub Releases, and Wally package manager.'
      },
      {
        title: 'Quick Start',
        file: 'getting-started/quick-start.md',
        link: '/getting-started/quick-start',
        description: 'Step-by-step guide to creating your first server-authoritative melee hitbox.'
      }
    ]
  },
  {
    sectionTitle: 'Core Concepts',
    items: [
      {
        title: 'Architecture & Authority',
        file: 'concepts/architecture.md',
        link: '/concepts/architecture',
        description: 'Server authority model and separation of infrastructure vs gameplay boundaries.'
      },
      {
        title: 'Hitbox Lifecycle',
        file: 'concepts/lifecycle.md',
        link: '/concepts/lifecycle',
        description: 'Finite state machine transitions (Idle, Active, Stopped, Cooldown) and object pooling.'
      },
      {
        title: 'Spatial Queries (Box & Sphere)',
        file: 'concepts/spatial-detection.md',
        link: '/concepts/spatial-detection',
        description: 'Box and Sphere spatial detection algorithms and dynamic CFrame tracking.'
      },
      {
        title: 'Velocity Prediction',
        file: 'concepts/prediction.md',
        link: '/concepts/prediction',
        description: 'Linear, Angular, and LinearAngular velocity extrapolation to eliminate ping whiffs.'
      },
      {
        title: 'Continuous Attacks',
        file: 'concepts/continuous-attacks.md',
        link: '/concepts/continuous-attacks',
        description: 'HitResetInterval for continuous damage, channeling skills, lasers, and persistent auras.'
      }
    ]
  },
  {
    sectionTitle: 'API Reference',
    items: [
      {
        title: 'Hitbox API',
        file: 'api/hitbox.md',
        link: '/api/hitbox',
        description: 'Constructor, properties, signals, lifecycle methods, and state queries for Hitbox class.'
      },
      {
        title: 'Signal API',
        file: 'api/signal.md',
        link: '/api/signal',
        description: 'Lightweight synchronous event primitive with FireFast and FireSafe dispatch.'
      },
      {
        title: 'Timer API',
        file: 'api/timer.md',
        link: '/api/timer',
        description: 'Temporal infrastructure primitive backed by Scheduler.'
      },
      {
        title: 'Await Synchronization API',
        file: 'api/await.md',
        link: '/api/await',
        description: 'Coroutine synchronization, cancellation tokens, barriers, mutexes, and retry utilities.'
      },
      {
        title: 'CharacterService API',
        file: 'api/character-service.md',
        link: '/api/character-service',
        description: 'Type-safe LocalPlayer character and component access getters and signals.'
      },
      {
        title: 'Shared Types',
        file: 'api/types.md',
        link: '/api/types',
        description: 'Exported Luau type definitions for strict type checking.'
      }
    ]
  },
  {
    sectionTitle: 'Guides & Patterns',
    items: [
      {
        title: 'Melee Combat System',
        file: 'guides/melee-combat.md',
        link: '/guides/melee-combat',
        description: 'Building production-ready melee combos and hit detection.'
      },
      {
        title: 'Radial & Explosion AoE',
        file: 'guides/aoe-abilities.md',
        link: '/guides/aoe-abilities',
        description: 'Spherical area-of-effect abilities and shockwave hitboxes.'
      },
      {
        title: 'Channeling & Auras',
        file: 'guides/channeling-auras.md',
        link: '/guides/channeling-auras',
        description: 'Persistent damage-over-time and aura fields.'
      },
      {
        title: 'Pooling & Performance',
        file: 'guides/pooling-performance.md',
        link: '/guides/pooling-performance',
        description: 'Object recycling and framework-level allocation reduction best practices.'
      },
      {
        title: 'Debug Visualizer',
        file: 'guides/debugging-visualizer.md',
        link: '/guides/debugging-visualizer',
        description: 'In-game visualizer parts for hitboxes during debugging.'
      }
    ]
  },
  {
    sectionTitle: 'Development & Contributing',
    items: [
      {
        title: 'Contributing Guidelines',
        file: 'development/contributing.md',
        link: '/development/contributing',
        description: 'Development setup and coding guidelines.'
      },
      {
        title: 'Automated Testing Suite',
        file: 'development/testing.md',
        link: '/development/testing',
        description: 'TestEZ test runner and unit test execution.'
      },
      {
        title: 'Changelog',
        file: 'development/changelog.md',
        link: '/development/changelog',
        description: 'Version release notes and changes.'
      }
    ]
  },
  {
    sectionTitle: 'Reference',
    items: [
      {
        title: 'AI Documentation Layer',
        file: 'reference/ai-docs.md',
        link: '/reference/ai-docs',
        description: 'Overview of static AI-readable documentation files (llms.txt, ai.md, llms-full.txt) and usage instructions.'
      },
      {
        title: 'FAQ',
        file: 'reference/faq.md',
        link: '/reference/faq',
        description: 'Frequently asked questions.'
      },
      {
        title: 'Troubleshooting',
        file: 'reference/troubleshooting.md',
        link: '/reference/troubleshooting',
        description: 'Common issues and resolution steps.'
      },
      {
        title: 'License',
        file: 'reference/license.md',
        link: '/reference/license',
        description: 'MIT License details.'
      }
    ]
  }
];

/**
 * Sanitizes Markdown content by stripping frontmatter, Vue components, converting VitePress container tags,
 * and normalizing non-ASCII symbols into clean ASCII text.
 */
function cleanMarkdown(content: string): string {
  let text = content;

  // 1. Remove YAML frontmatter
  text = text.replace(/^---\r?\n[\s\S]*?\r?\n---\r?\n/, '');

  // 2. Normalize tree box-drawing characters to clean ASCII
  text = text.replace(/└──/g, '+--')
             .replace(/├──/g, '+--')
             .replace(/│/g, '|');

  // 3. Normalize non-ASCII emojis to clean ASCII text
  text = text.replace(/⛔/g, '[!]')
             .replace(/❌/g, '[X]')
             .replace(/✅/g, '[OK]')
             .replace(/⚔️|⚡|🎯|🔄|📈|🛡️/g, '');

  // 4. Convert VitePress container blocks (::: tip [title], ::: warning, ::: info, ::: caution, ::: danger)
  text = text.replace(/:::\s*(info|tip|warning|caution|danger)(?:\s+\[?(.*?)\]?)?\r?\n/gi, (_, type, title) => {
    const label = title ? ` ${title}` : '';
    const alertType = type.toUpperCase() === 'INFO' ? 'NOTE' : type.toUpperCase();
    return `> [!${alertType}]${label}\n> `;
  });
  text = text.replace(/:::\s*\r?\n/g, '\n');

  // 5. Convert ::: details container blocks
  text = text.replace(/:::\s*details(?:\s+(.*))?\r?\n/gi, (_, title) => {
    return `<details><summary>${title || 'Details'}</summary>\n\n`;
  });

  // 6. Remove Vue script tags or custom Vue components (<script setup>...</script>, <Badge ... />)
  text = text.replace(/<script[\s\S]*?<\/script>/gi, '');
  text = text.replace(/<Badge[\s\S]*?\/>/gi, '');

  // 7. Clean excessive empty lines
  text = text.replace(/\n{3,}/g, '\n\n');

  return text.trim();
}

/**
 * Generates llms.txt adhering to standard llmstxt.org format.
 */
function generateLlmsTxt(): string {
  let out = `# ${PROJECT_NAME}\n\n`;
  out += `> ${PROJECT_DESC}\n\n`;
  out += `Version: ${VERSION}\n\n`;

  for (const section of SECTIONS) {
    out += `## ${section.sectionTitle}\n\n`;
    for (const item of section.items) {
      out += `- [${item.title}](${BASE_URL}${item.link}): ${item.description}\n`;
    }
    out += `\n`;
  }

  out += `## AI Documentation\n\n`;
  out += `- [Curated AI Documentation](${BASE_URL}/ai.txt): High-density AI-oriented guide containing strict rules, constraints, complete code examples, and explicit API definitions for AI assistants.\n`;
  out += `- [Full Documentation Text](${BASE_URL}/llms-full.txt): Complete concatenated documentation in a single plain text file.\n`;

  return out.trim() + '\n';
}

/**
 * Generates ai.md - a curated AI-oriented technical specification document.
 */
function generateAiMd(): string {
  let out = `# ${PROJECT_NAME} -- AI Reference & Context Guide\n\n`;
  out += `Version: ${VERSION}\n\n`;
  out += `This document provides concise, explicit, and accurate context for AI coding assistants (e.g. Claude Code, Cursor, Gemini CLI, Codex) writing Luau code with Axiom Hitbox Framework v${VERSION}.\n\n`;
  out += `---\n\n`;

  out += `## 1. Project Overview\n\n`;
  out += `Axiom Hitbox is a server-authoritative spatial query framework for Roblox Luau.\n`;
  out += `It decouples infrastructure primitives (spatial detection, timing, cancellation, object pooling) from gameplay rules (damage, combos, VFX, cooldowns).\n\n`;

  out += `### Key Architecture Rules\n`;
  out += `- **Server Authority**: Spatial detection and damage calculation MUST run on the server. Clients must never calculate or transmit hit target arrays over \`RemoteEvent\`s.\n`;
  out += `- **Strict Type Safety**: All scripts using Axiom should enforce \`--!strict\` Luau mode.\n`;
  out += `- **Allocation Reduction**: Retains pre-instantiated Hitbox objects in an adaptive pool (\`Hitbox.new()\`) and reuses \`OverlapParams\` instances to reduce framework-side memory allocation and GC pressure during combat.\n\n`;

  out += `---\n\n`;

  out += `## 2. Core API Reference & Signatures\n\n`;

  // Append Hitbox API section from docs/api/hitbox.md
  const hitboxPath = path.join(DOCS_DIR, 'api/hitbox.md');
  if (fs.existsSync(hitboxPath)) {
    out += `### Hitbox Class API\n\n`;
    out += cleanMarkdown(fs.readFileSync(hitboxPath, 'utf8')) + `\n\n`;
  }

  // Append Signal API section from docs/api/signal.md
  const signalPath = path.join(DOCS_DIR, 'api/signal.md');
  if (fs.existsSync(signalPath)) {
    out += `### Signal API\n\n`;
    out += cleanMarkdown(fs.readFileSync(signalPath, 'utf8')) + `\n\n`;
  }

  // Append Timer API section from docs/api/timer.md
  const timerPath = path.join(DOCS_DIR, 'api/timer.md');
  if (fs.existsSync(timerPath)) {
    out += `### Timer API\n\n`;
    out += cleanMarkdown(fs.readFileSync(timerPath, 'utf8')) + `\n\n`;
  }

  // Append Await API section from docs/api/await.md
  const awaitPath = path.join(DOCS_DIR, 'api/await.md');
  if (fs.existsSync(awaitPath)) {
    out += `### Await Synchronization API\n\n`;
    out += cleanMarkdown(fs.readFileSync(awaitPath, 'utf8')) + `\n\n`;
  }

  // Append CharacterService API section from docs/api/character-service.md
  const charPath = path.join(DOCS_DIR, 'api/character-service.md');
  if (fs.existsSync(charPath)) {
    out += `### CharacterService API\n\n`;
    out += cleanMarkdown(fs.readFileSync(charPath, 'utf8')) + `\n\n`;
  }

  // Append Types API section from docs/api/types.md
  const typesPath = path.join(DOCS_DIR, 'api/types.md');
  if (fs.existsSync(typesPath)) {
    out += `### Exported Luau Types\n\n`;
    out += cleanMarkdown(fs.readFileSync(typesPath, 'utf8')) + `\n\n`;
  }

  out += `---\n\n`;

  out += `## 3. Mandatory Rules & Constraints\n\n`;
  out += `> [!IMPORTANT]\n`;
  out += `> 1. **Do Not Instantiate Internal Pool Directly**: Always use \`Hitbox.new()\`. Never instantiate or mutate internal \`_POOL\` primitives.\n`;
  out += `> 2. **Always Cleanup via \`:Destroy()\`**: Call \`hb:Destroy()\` when a hitbox completes its duration to return it to the adaptive pool and disconnect signals.\n`;
  out += `> 3. **Post-Destroy Invariant**: Do NOT dereference or modify a \`Hitbox\` instance after calling \`:Destroy()\`. Accessing a destroyed instance logs warnings and blocks execution.\n`;
  out += `> 4. **Exception-Safe Handlers**: \`hb.OnHit\` uses \`FireSafe\`. Callbacks that throw errors will log warnings without crashing the RunService loop.\n`;
  out += `> 5. **Dynamic Frame Tracking**: When assigning \`hb.CFrame = character.HumanoidRootPart\`, pass the \`BasePart\` directly rather than pre-evaluating \`BasePart.CFrame\` if real-time tracking is desired.\n`;
  out += `> 6. **Continuous Attack Reset**: For DoT skills, auras, or beam attacks, set \`hb.HitResetInterval = number\` to automatically reset hit memory periodically.\n\n`;

  out += `---\n\n`;

  out += `## 4. Common Anti-Patterns & API Mistakes\n\n`;
  out += `### [X] Incorrect: Accepting target hit lists from client over RemoteEvents\n`;
  out += `\`\`\`lua\n`;
  out += `-- DO NOT DO THIS (Vulnerable to exploiters)\n`;
  out += `DamageRemote.OnServerEvent:Connect(function(player, hitTargets)\n`;
  out += `    for _, target in hitTargets do target.Humanoid:TakeDamage(50) end\n`;
  out += `end)\n`;
  out += `\`\`\`\n\n`;

  out += `### [OK] Correct: Server-authoritative Hitbox activation\n`;
  out += `\`\`\`lua\n`;
  out += `-- DO THIS (Server calculates hit detection)\n`;
  out += `SkillRemote.OnServerEvent:Connect(function(player)\n`;
  out += `    local char = player.Character or return\n`;
  out += `    local hb = Hitbox.new()\n`;
  out += `    hb.Shape = "Box"\n`;
  out += `    hb.Size = Vector3.new(5, 6, 4)\n`;
  out += `    hb.CFrame = char:FindFirstChild("HumanoidRootPart")\n`;
  out += `    hb.Offset = CFrame.new(0, 0, -3)\n`;
  out += `    hb.Duration = 0.3\n`;
  out += `    hb.Ignore = { char }\n`;
  out += `    hb.OnHit:Connect(function(model, humanoid)\n`;
  out += `        humanoid:TakeDamage(25)\n`;
  out += `    end)\n`;
  out += `    hb:Start()\n`;
  out += `    task.delay(hb.Duration + 0.05, function()\n`;
  out += `        hb:Destroy()\n`;
  out += `    end)\n`;
  out += `end)\n`;
  out += `\`\`\`\n\n`;

  out += `### [X] Incorrect: Forgetting to destroy hitbox after duration\n`;
  out += `\`\`\`lua\n`;
  out += `-- DO NOT DO THIS (Memory leak and pool exhaustion)\n`;
  out += `local hb = Hitbox.new()\n`;
  out += `hb:Start()\n`;
  out += `-- missing hb:Destroy()\n`;
  out += `\`\`\`\n\n`;

  out += `### [OK] Correct: Immediate or delayed recycling to object pool\n`;
  out += `\`\`\`lua\n`;
  out += `-- DO THIS\n`;
  out += `local hb = Hitbox.new()\n`;
  out += `hb.Duration = 0.5\n`;
  out += `hb:Start()\n`;
  out += `task.delay(hb.Duration + 0.05, function()\n`;
  out += `    hb:Destroy()\n`;
  out += `end)\n`;
  out += `\`\`\`\n`;

  return out.trim() + '\n';
}

/**
 * Generates llms-full.txt by concatenating all public documentation markdown files in order.
 */
function generateLlmsFullTxt(): string {
  let out = `# ${PROJECT_NAME} — Complete Documentation\n\n`;
  out += `> ${PROJECT_DESC}\n\n`;
  out += `Version: ${VERSION}\n\n`;
  out += `This file contains the complete public documentation for ${PROJECT_NAME} v${VERSION}.\n\n`;
  out += `================================================================================\n\n`;

  for (const section of SECTIONS) {
    out += `# SECTION: ${section.sectionTitle}\n\n`;

    for (const item of section.items) {
      const filePath = path.join(DOCS_DIR, item.file);
      if (!fs.existsSync(filePath)) {
        console.warn(`[generate-ai-docs] Warning: File not found: ${filePath}`);
        continue;
      }

      const rawContent = fs.readFileSync(filePath, 'utf8');
      const cleaned = cleanMarkdown(rawContent);

      out += `--------------------------------------------------------------------------------\n`;
      out += `## Page: ${item.title} (${item.file})\n`;
      out += `--------------------------------------------------------------------------------\n\n`;
      out += cleaned + `\n\n`;
    }
  }

  return out.trim() + '\n';
}

/**
 * Main execution routine.
 */
function main() {
  console.log(`[generate-ai-docs] Generating AI documentation for ${PROJECT_NAME} v${VERSION}...`);

  // 1. Generate llms.txt
  const llmsTxtContent = generateLlmsTxt();
  const llmsTxtPath = path.join(PUBLIC_DIR, 'llms.txt');
  fs.writeFileSync(llmsTxtPath, llmsTxtContent, 'utf8');
  console.log(`  ✓ Generated: ${path.relative(ROOT_DIR, llmsTxtPath)} (${llmsTxtContent.length} bytes)`);

  // 2. Generate ai.txt in docs/public/ as raw static file
  const aiMdContent = generateAiMd();
  const aiTxtPath = path.join(PUBLIC_DIR, 'ai.txt');
  const aiMdPublicPath = path.join(PUBLIC_DIR, 'ai.md');
  const aiMdDocsPath = path.join(DOCS_DIR, 'ai.md');

  // Delete any ai.md files completely
  if (fs.existsSync(aiMdDocsPath)) {
    fs.unlinkSync(aiMdDocsPath);
  }
  if (fs.existsSync(aiMdPublicPath)) {
    fs.unlinkSync(aiMdPublicPath);
  }

  // Write raw ai.txt for AI assistants & direct static view
  fs.writeFileSync(aiTxtPath, aiMdContent, 'utf8');
  console.log(`  ✓ Generated raw AI doc: ${path.relative(ROOT_DIR, aiTxtPath)} (${aiMdContent.length} bytes)`);

  // 3. Generate llms-full.txt
  const llmsFullTxtContent = generateLlmsFullTxt();
  const llmsFullTxtPath = path.join(PUBLIC_DIR, 'llms-full.txt');
  fs.writeFileSync(llmsFullTxtPath, llmsFullTxtContent, 'utf8');
  console.log(`  ✓ Generated: ${path.relative(ROOT_DIR, llmsFullTxtPath)} (${llmsFullTxtContent.length} bytes)`);

  // Also sync to docs/.vitepress/dist if dist exists
  const distDir = path.join(DOCS_DIR, '.vitepress', 'dist');
  if (fs.existsSync(distDir)) {
    fs.writeFileSync(path.join(distDir, 'llms.txt'), llmsTxtContent, 'utf8');
    fs.writeFileSync(path.join(distDir, 'ai.txt'), aiMdContent, 'utf8');
    fs.writeFileSync(path.join(distDir, 'llms-full.txt'), llmsFullTxtContent, 'utf8');
    if (fs.existsSync(path.join(distDir, 'ai.md'))) {
      fs.unlinkSync(path.join(distDir, 'ai.md'));
    }
    console.log(`  ✓ Synced AI doc files directly to ${path.relative(ROOT_DIR, distDir)}`);
  }

  console.log(`[generate-ai-docs] Successfully generated all AI documentation files!`);
}

main();

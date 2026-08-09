# AI Documentation Layer

Axiom Hitbox Framework provides static, AI-readable documentation files designed to enable AI coding assistants (such as **Claude Code**, **Cursor**, **Gemini CLI**, **Codex**, and **GitHub Copilot**) to accurately understand and write code using Axiom without having to crawl the repository.

---

## Available AI Documentation

| Document | Description | Direct Link |
| :--- | :--- | :--- |
| **`ai.txt`** | Curated AI technical specification with explicit signatures, strict rules, and Luau examples | [Raw `/ai.txt`](/ai.txt) |
| **`ai.md`** | Curated AI technical specification in markdown format | [Raw `/ai.md`](/ai.md) |
| **`llms.txt`** | Standardized documentation index listing main topics and section links | [Raw `/llms.txt`](/llms.txt) |
| **`llms-full.txt`** | Full concatenated plain-text representation of all public documentation | [Raw `/llms-full.txt`](/llms-full.txt) |

---

## How to Use with AI Tools

### Cursor
Add the curated AI guide directly to your Cursor documentation context:
1. Open **Cursor Settings** > **Features** > **Docs**.
2. Add custom documentation URL: `https://zAxn1e.github.io/axiom-hitbox/ai.txt`
3. Use `@ai.txt` in Cursor Chat when asking Axiom questions.

### Claude Code / Gemini CLI / Terminal Assistants
Direct your terminal AI assistant to read `llms.txt` or `ai.txt` before generating code:
```bash
# Example prompting Claude Code or Gemini CLI:
"Read https://zAxn1e.github.io/axiom-hitbox/ai.txt and create a server script for a 3-hit melee combo."
```

### Prompt Engineering / Custom Instructions
Include the direct raw URL of `ai.txt` in your project's `.cursorrules`, `SYSTEM_PROMPT`, or Copilot instructions:
```text
Refer to Axiom Hitbox Framework API reference at:
https://zAxn1e.github.io/axiom-hitbox/ai.txt
```

---

## Automation & Synchronization

These AI documentation files are automatically generated during `bun run docs:build` using `scripts/generate-ai-docs.ts`. They remain 100% synchronized with the main VitePress documentation site.

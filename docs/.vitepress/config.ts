import { defineConfig } from 'vitepress'
import { withMermaid } from 'vitepress-plugin-mermaid'

const base = process.env.GITHUB_ACTIONS ? '/axiom-hitbox/' : '/'

export default withMermaid(
  defineConfig({
    title: 'Axiom Hitbox Framework',
    description: 'High-performance, server-authoritative Roblox hitbox and synchronization framework',
    base: base,
    cleanUrls: true,
    lastUpdated: true,
    ignoreDeadLinks: true,

    mermaid: {
      theme: 'dark'
    },

    head: [
      ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}logo.svg` }],
      ['link', { rel: 'alternate icon', type: 'image/png', href: `${base}logo.svg` }],
      ['meta', { name: 'theme-color', content: '#10b981' }],
      ['meta', { name: 'og:type', content: 'website' }],
      ['meta', { name: 'og:site_name', content: 'Axiom Hitbox Framework' }],
      ['meta', { name: 'og:title', content: 'Axiom Hitbox Framework' }],
      ['meta', { name: 'og:description', content: 'High-performance, server-authoritative Roblox hitbox and synchronization framework' }]
    ],

    themeConfig: {
      logo: '/logo.svg',
      siteTitle: 'Axiom Hitbox',

      nav: [
        { text: 'Guide', link: '/getting-started/quick-start', activeMatch: '/(getting-started|concepts|guides)/' },
        { text: 'API Reference', link: '/api/hitbox', activeMatch: '/api/' },
        {
          text: 'AI Docs',
          items: [
            { text: 'Overview & Usage', link: '/reference/ai-docs' },
            { text: 'ai.txt (Curated AI Spec)', link: '/ai.txt', target: '_blank' },
            { text: 'llms.txt (Index)', link: '/llms.txt', target: '_blank' },
            { text: 'llms-full.txt (Full Text)', link: '/llms-full.txt', target: '_blank' }
          ]
        },
        { text: 'Development', link: '/development/contributing', activeMatch: '/development/' },
        { text: 'v1.4.0', link: '/development/changelog' }
      ],

      sidebar: [
        {
          text: 'Getting Started',
          collapsed: false,
          items: [
            { text: 'Installation', link: '/getting-started/installation' },
            { text: 'Quick Start', link: '/getting-started/quick-start' }
          ]
        },
        {
          text: 'Core Concepts',
          collapsed: false,
          items: [
            { text: 'Architecture & Authority', link: '/concepts/architecture' },
            { text: 'Hitbox Lifecycle', link: '/concepts/lifecycle' },
            { text: 'Spatial Queries (Box & Sphere)', link: '/concepts/spatial-detection' },
            { text: 'Velocity Prediction', link: '/concepts/prediction' },
            { text: 'Continuous Attacks', link: '/concepts/continuous-attacks' }
          ]
        },
        {
          text: 'API Reference',
          collapsed: false,
          items: [
            { text: 'Hitbox API', link: '/api/hitbox' },
            { text: 'Signal API', link: '/api/signal' },
            { text: 'Timer & Scheduler API', link: '/api/timer' },
            { text: 'Await Synchronization API', link: '/api/await' },
            { text: 'CharacterService API', link: '/api/character-service' },
            { text: 'Shared Types', link: '/api/types' }
          ]
        },
        {
          text: 'Guides & Patterns',
          collapsed: false,
          items: [
            { text: 'Melee Combat System', link: '/guides/melee-combat' },
            { text: 'Radial & Explosion AoE', link: '/guides/aoe-abilities' },
            { text: 'Channeling & Auras', link: '/guides/channeling-auras' },
            { text: 'Pooling & Performance', link: '/guides/pooling-performance' },
            { text: 'Debug Visualizer', link: '/guides/debugging-visualizer' }
          ]
        },
        {
          text: 'Development & Contributing',
          collapsed: false,
          items: [
            { text: 'Contributing Guidelines', link: '/development/contributing' },
            { text: 'Automated Testing Suite', link: '/development/testing' },
            { text: 'Changelog', link: '/development/changelog' }
          ]
        },
        {
          text: 'Reference',
          collapsed: false,
          items: [
            { text: 'AI Documentation Overview', link: '/reference/ai-docs' },
            { text: 'ai.txt (Curated AI Spec)', link: '/ai.txt', target: '_blank' },
            { text: 'FAQ', link: '/reference/faq' },
            { text: 'Troubleshooting', link: '/reference/troubleshooting' },
            { text: 'License', link: '/reference/license' }
          ]
        }
      ],

      search: {
        provider: 'local'
      },

      socialLinks: [
        { icon: 'github', link: 'https://github.com/zAxn1e/axiom-hitbox' }
      ],

      editLink: {
        pattern: 'https://github.com/zAxn1e/axiom-hitbox/edit/main/docs/:path',
        text: 'Edit this page on GitHub'
      },

      footer: {
        message: 'Released under the MIT License.',
        copyright: 'Copyright © 2025-2026 Iv_0x'
      }
    }
  })
)

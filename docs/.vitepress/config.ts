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

    sitemap: {
      hostname: 'https://zaxn1e.github.io/axiom-hitbox/'
    },

    head: [
      ['link', { rel: 'icon', type: 'image/svg+xml', href: `${base}logo.svg` }],
      ['link', { rel: 'alternate icon', type: 'image/png', href: `${base}logo.svg` }],
      ['meta', { name: 'theme-color', content: '#10b981' }],
      ['meta', { name: 'author', content: 'Iv_0x' }],
      ['meta', { name: 'keywords', content: 'Roblox, Luau, Hitbox, Combat System, Spatial Query, Server-Authoritative, Game Development, Roblox Studio' }],
      ['meta', { name: 'google-site-verification', content: 'googlec8ceadd962aff159' }],
      ['link', { rel: 'alternate', type: 'text/plain', title: 'AI Documentation Specification', href: `${base}ai.txt` }],
      ['link', { rel: 'alternate', type: 'text/plain', title: 'LLMs Context Index', href: `${base}llms.txt` }]
    ],

    transformHead({ pageData }) {
      const hostname = 'https://zaxn1e.github.io/axiom-hitbox'
      
      let pagePath = pageData.relativePath
        .replace(/index\.md$/, '')
        .replace(/\.md$/, '')
      
      if (pagePath && !pagePath.startsWith('/')) {
        pagePath = '/' + pagePath
      }
      if (!pagePath || pagePath === '/index') {
        pagePath = '/'
      }

      const canonicalUrl = `${hostname}${pagePath}`
      const ogImageUrl = `${hostname}/logo.svg`
      
      const pageTitle = pageData.title ? `${pageData.title} | Axiom Hitbox` : 'Axiom Hitbox Framework'
      const pageDesc = pageData.description || pageData.frontmatter?.description || 'High-performance, server-authoritative Roblox hitbox and synchronization framework'

      const headElements: any[] = [
        ['link', { rel: 'canonical', href: canonicalUrl }],
        ['meta', { property: 'og:type', content: pageData.relativePath === 'index.md' ? 'website' : 'article' }],
        ['meta', { property: 'og:site_name', content: 'Axiom Hitbox Framework' }],
        ['meta', { property: 'og:title', content: pageTitle }],
        ['meta', { property: 'og:description', content: pageDesc }],
        ['meta', { property: 'og:url', content: canonicalUrl }],
        ['meta', { property: 'og:image', content: ogImageUrl }],
        ['meta', { property: 'og:image:alt', content: 'Axiom Hitbox Framework Logo' }],
        ['meta', { name: 'twitter:card', content: 'summary' }],
        ['meta', { name: 'twitter:title', content: pageTitle }],
        ['meta', { name: 'twitter:description', content: pageDesc }],
        ['meta', { name: 'twitter:image', content: ogImageUrl }]
      ]

      if (pageData.relativePath === 'index.md') {
        const websiteSchema = {
          '@context': 'https://schema.org',
          '@type': 'SoftwareApplication',
          'name': 'Axiom Hitbox Framework',
          'operatingSystem': 'Roblox Platform',
          'applicationCategory': 'DeveloperApplication',
          'description': pageDesc,
          'url': hostname,
          'author': {
            '@type': 'Organization',
            'name': 'Iv_0x'
          },
          'offers': {
            '@type': 'Offer',
            'price': '0',
            'priceCurrency': 'USD'
          }
        }
        headElements.push([
          'script',
          { type: 'application/ld+json' },
          JSON.stringify(websiteSchema)
        ])
      } else {
        const techArticleSchema = {
          '@context': 'https://schema.org',
          '@type': 'TechArticle',
          'headline': pageData.title || 'Axiom Hitbox Documentation',
          'description': pageDesc,
          'url': canonicalUrl,
          'mainEntityOfPage': {
            '@type': 'WebPage',
            '@id': canonicalUrl
          },
          'author': {
            '@type': 'Organization',
            'name': 'Iv_0x'
          },
          'publisher': {
            '@type': 'Organization',
            'name': 'Axiom Hitbox Framework'
          }
        }
        headElements.push([
          'script',
          { type: 'application/ld+json' },
          JSON.stringify(techArticleSchema)
        ])
      }

      return headElements
    },

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
            { text: 'ai.txt (Curated Spec)', link: `${base}ai.txt`, target: '_blank' },
            { text: 'llms.txt (Index)', link: `${base}llms.txt`, target: '_blank' },
            { text: 'llms-full.txt (Full Text)', link: `${base}llms-full.txt`, target: '_blank' }
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
            { text: 'ai.txt (Curated Spec)', link: `${base}ai.txt`, target: '_blank' },
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

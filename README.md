# TB Discourse SEO

A [Discourse](https://www.discourse.org/) plugin with two SEO features:

1. **Noindex per category** — adds the `X-Robots-Tag: noindex` HTTP header to topics belonging to specific categories, preventing search engines (like Google) from indexing those pages.
2. **hreflang for translated topics** — injects `<link rel="alternate" hreflang="...">` tags into the `<head>` of topic pages that have translations, so search engines can discover and serve the correct language version of each topic.

---

## Feature 1 — Noindex per category

### How It Works

1. **Category Setting** — A new checkbox is added to the category edit form (General tab):

   > `[ ] Add the tag Noindex in topics from this category`

2. **HTTP Header Injection** — When a topic belongs to a category with this setting enabled, the plugin automatically adds the following header to the HTTP response:

   ```
   X-Robots-Tag: noindex
   ```

3. **Per-category only** — The setting applies strictly to topics whose category has the box checked. Subcategories do **not** inherit the parent's setting; enable it on each category you want to deindex.

### Usage

1. Go to **Admin > Categories** and edit the category you want to deindex.
2. In the **General** tab, check the box **"Add the tag Noindex in topics from this category"**.
3. Save the category.

All topics in that category will now return `X-Robots-Tag: noindex`, signaling search engines not to index those pages.

---

## Feature 2 — hreflang for translated topics

This feature builds on Discourse's built-in **content localization** (automatic translation) feature. When a topic has translated versions (rows in the `topic_localizations` table), the plugin emits `hreflang` annotations in the page `<head>` so search engines can discover and serve the correct language version.

### How It Works

For every topic page (both the regular Ember layout and the crawler layout served to bots), the plugin:

1. **Detects the configured translation locales** from the Discourse site setting `content_localization_supported_locales`, plus the site `default_locale`.
2. **Detects which locales the topic actually has** by querying `TopicLocalization` for that topic. Only locales that are **both** configured **and** actually translated for the topic are advertised — unlike Discourse core, which advertises every configured locale on every page even when no translation exists (technically incorrect hreflang).
3. **Emits the `<link>` tags** into the `<head>`:

   ```html
   <link rel="alternate" hreflang="en"        href="https://example.com/t/slug/123" />
   <link rel="alternate" hreflang="es"        href="https://example.com/t/slug/123?tl=es" />
   <link rel="alternate" hreflang="pt-BR"     href="https://example.com/t/slug/123?tl=pt_BR" />
   <link rel="alternate" hreflang="x-default" href="https://example.com/t/slug/123" />
   ```

   - The **default locale** gets a self-referencing tag pointing to the canonical topic URL.
   - Each **translated locale** points to the topic URL with the `?tl=<locale>` parameter (Discourse's translation locale parameter).
   - An **`x-default`** tag pointing to the canonical (default-language) topic URL is always included (standard hreflang best practice recommended by Google).
   - Discourse locale codes are converted to BCP 47 / hreflang format (e.g. `pt_BR` → `pt-BR`, `zh_CN` → `zh-CN`).

### Required Discourse settings

For the translated `?tl=<locale>` URLs to actually serve translated content to search engines, the following **core Discourse** settings must be enabled:

| Discourse setting | Required value | Why |
|-------------------|----------------|-----|
| `content_localization_enabled` | `true` | Master switch for content localization. The plugin emits nothing without it. |
| `content_localization_supported_locales` | your target locales (e.g. `es\|pt_BR\|zh_CN`) | The list of languages content is translated into. |
| `set_locale_from_param` | `true` | Makes `?tl=<locale>` actually switch the displayed language. |
| `content_localization_crawler_param` | **`false`** (recommended) | When `true`, Discourse core emits its **own** (over-broad) hreflang tags. Keep it **off** to avoid duplicate/conflicting tags, since this plugin emits the correct per-topic tags instead. |

> **Note on translation scope:** Discourse has no built-in "translate only these categories" setting — the automatic translation engine (discourse-ai) translates all eligible public content, and category scoping is typically done via Discourse Automation. This plugin does not need to know how translation was scoped: it detects translations **empirically per topic**, so hreflang tags only appear on topics that actually have translations (i.e. the topics in your translated categories).

---

## Installation

Follow the official Discourse plugin installation guide and add this plugin to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: /var/www/discourse
        cmd:
          - git clone https://github.com/mobilon/tb-discourse-seo.git
```

Then rebuild the container:

```bash
./launcher rebuild app
```

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `tb_discourse_seo_enabled` | `true` | Enable or disable the plugin globally |
| `tb_discourse_seo_hreflang_enabled` | `true` | Enable or disable the hreflang feature |

## License

MIT

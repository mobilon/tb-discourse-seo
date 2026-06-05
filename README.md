# TB Discourse SEO

A [Discourse](https://www.discourse.org/) plugin that adds the `X-Robots-Tag: noindex` HTTP header to topics belonging to specific categories, preventing search engines (like Google) from indexing those pages.

## How It Works

1. **Category Setting** — A new checkbox is added to the category edit form (General tab):

   > `[ ] Add the tag Noindex in topics from this category`

2. **HTTP Header Injection** — When a topic belongs to a category with this setting enabled, the plugin automatically adds the following header to the HTTP response:

   ```
   X-Robots-Tag: noindex
   ```

3. **Per-category only** — The setting applies strictly to topics whose category has the box checked. Subcategories do **not** inherit the parent's setting; enable it on each category you want to deindex.

## Installation

Follow the official Discourse plugin installation guide and add this plugin to your `app.yml`:

```yaml
hooks:
  after_code:
    - exec:
        cd: /var/www/discourse
        cmd:
          - git clone https://github.com/mobilon/tb-discourse-seo.git plugins/tb-discourse-seo
```

Then rebuild the container:

```bash
./launcher rebuild app
```

## Usage

1. Go to **Admin > Categories** and edit the category you want to deindex.
2. In the **General** tab, check the box **"Add the tag Noindex in topics from this category"**.
3. Save the category.

All topics in that category will now return `X-Robots-Tag: noindex`, signaling search engines not to index those pages.

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `tb_discourse_seo_enabled` | `true` | Enable or disable the plugin globally |

## License

MIT

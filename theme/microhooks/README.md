# Tiny Theme microhooks — local archive

Tiny Theme exposes a small set of "hook" template files you can override
without forking the whole theme. To override a hook in Micro.blog:

1. Go to **Design → Edit Theme**.
2. Create a new template with the exact filename below.
3. Paste in the contents of the matching file from this folder.

This folder is a **local archive only** — Micro.blog does not pull from
GitHub for theme files. Keep these in sync by hand whenever you change a
hook in the Micro.blog UI.

## Hook points

Each filename here maps 1:1 to a Tiny Theme hook template:

| File                    | Hook point                                              |
| ----------------------- | ------------------------------------------------------- |
| `microhook_header.html` | Injected into `<head>`. Use for meta, fonts, analytics. |
| `microhook_footer.html` | Injected before `</body>`. Use for footer markup, JS.   |
| `microhook_post-header.html` | Rendered above each post's title.                  |
| `microhook_post-footer.html` | Rendered below each post's body (before replies). |

Empty by default — add files only when an override actually ships.

See: <https://www.tinymicroblog.com/> for the canonical hook reference.

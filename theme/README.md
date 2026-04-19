# theme/ — Tiny Theme local archive

Local archive of the custom CSS and microhook overrides applied to
[blog.dade.studio](https://blog.dade.studio) (Micro.blog, Tiny Theme).

Micro.blog stores theme customizations server-side; this folder is a
**read-only mirror kept by hand** so the design is recoverable from git
if the theme is reset, swapped, or accidentally cleared in the UI.

## Contents

- `custom.css` — paste-ready CSS for Micro.blog → Design → Edit CSS.
- `microhooks/` — optional Tiny Theme hook overrides
  (see `microhooks/README.md`).

## How to apply

### Custom CSS

1. Open Micro.blog → **Design** → **Edit CSS**.
2. Replace the contents of the box with `theme/custom.css`.
3. Click **Update CSS**. Changes are live immediately.

### Microhooks (optional)

1. Open Micro.blog → **Design** → **Edit Theme**.
2. For each file in `theme/microhooks/`, click **New Template**, name it
   exactly the same as the file, and paste the contents.
3. Save.

## How to re-apply after a theme reset

1. Re-select Tiny Theme in Micro.blog → Design.
2. Repeat **How to apply** above using the files in this folder.
3. Confirm the site renders correctly in both light and dark mode.

## Sync discipline

Whenever you change CSS or a hook in the Micro.blog UI:

1. Copy the new contents back into the matching file here.
2. Commit with a message like `chore(theme): sync custom.css from prod`.

This folder is **not** pulled by Micro.blog — it is documentation, not deployment.

# Uploading Neon Drift to itch.io

The file `dist/neon-drift-itch.zip` is a ready-to-upload HTML5 build. `index.html` sits at the root of the zip, which is what itch.io expects.

1. Sign in at https://itch.io and choose **Upload new project** (from your avatar menu, or go to https://itch.io/game/new).
2. Fill in:
   - **Title:** Neon Drift
   - **Project URL:** e.g. `https://<your-username>.itch.io/neon-drift`
   - **Short description:** Neon top-down arena survival shooter built in Godot 4.
   - **Classification:** Games
   - **Kind of project:** **HTML** (important: this makes it playable in the browser)
3. Under **Uploads**, click **Upload files** and pick `neon-drift-itch.zip`.
   Once it has uploaded, tick **"This file will be played in the browser"**.
4. Under **Embed options**:
   - **Viewport dimensions:** 1280 × 720 (the game scales to any size, so 960 × 540 also works)
   - Tick **Mobile friendly** (touch controls are built in) and **Fullscreen button**.
   - Leave **SharedArrayBuffer support** turned **off**. It isn't needed because this is a single-threaded web build.
5. Optional: add the screenshots from `docs/` and set the cover image.
6. Set **Visibility & access** to **Public** and click **Save & view page**.

You now have a permanent, login-free link (`https://<your-username>.itch.io/neon-drift`) you can put on job applications.

To update the game later, re-export it (`tools/godot --headless --export-release "Web" build/web/index.html`), re-zip `build/web/*` and replace the file on the same itch.io page.

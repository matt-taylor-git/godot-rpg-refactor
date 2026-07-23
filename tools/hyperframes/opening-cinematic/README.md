# Opening Cinematic

Title-neutral HyperFrames source for the game's 10.4-second opening cinematic.
The composition intentionally contains no game name, logo, or baked-in narrative
copy. Its final frame uses the same gateway illustration as the main menu.

## Validate and render

From this directory:

```powershell
npm run check
npx hyperframes@0.7.68 render --output opening-final.mp4 --quality high --fps 30 --workers 1
```

Convert the rendered master to the format supported natively by Godot:

```powershell
ffmpeg -y -i opening-final.mp4 -an -c:v libtheora -q:v 7 -pix_fmt yuv420p -r 30 ../../../assets/video/opening_cinematic.ogv
```

The source illustrations in `assets/` are copies of existing game artwork so the
composition remains self-contained and deterministic.

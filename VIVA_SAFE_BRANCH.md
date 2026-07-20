# Hydrae Viva Safe Branch

This branch intentionally leaves the deployed GitHub Pages files at the
repository root unchanged.

The corrected Flutter source lives under `source/`. The validation workflow
formats, analyzes, and builds that source, then uploads the web bundle as a
workflow artifact. It does **not** deploy to GitHub Pages and cannot replace the
existing viva website.

Only after the build passes and the owner explicitly approves deployment should
any generated bundle be copied to the repository root or published separately.

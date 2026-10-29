# Releasing

A release of abap-cloud-gui is a tag `vX.Y.Z` on `main`. abapGit users pull
the repository at the tag or import the zip of its GitHub release;
`.github/workflows/release.yaml` builds that release when the tag is pushed.

## What a release is for

`main` is what the CI proved; a tag is what an installation pins. The
public API of `src/01` follows semantic versioning from 1.0.0 on
(CHANGELOG.md, 1.0.0): removed or changed is major, added is minor, fixed
is a patch. report2cloud writes against that API, so a major release of the
runtime is a major release of the converter too - they are one version.

## Cutting a release

1. On `main`, green. Move the entries of `## Unreleased` in CHANGELOG.md
   into a section `## X.Y.Z - YYYY-MM-DD` (the date of the tag), and set
   `"version"` in package.json (and package-lock.json) to `X.Y.Z`:

   ```sh
   npm version X.Y.Z --no-git-tag-version
   ```

2. Commit that as `release vX.Y.Z` through a pull request, merge it.
3. Tag the merge commit, annotated, and push the tag:

   ```sh
   git tag -a vX.Y.Z -m "release vX.Y.Z" && git push origin vX.Y.Z
   ```

   `--follow-tags` alone would skip a lightweight tag without a word; the
   explicit push does not.

The workflow then

- refuses when the tag, package.json and the CHANGELOG section disagree;
- runs the gates once more on the tagged commit (`npm run check`);
- builds `abap-cloud-gui-X.Y.Z.zip` (`.abapgit.xml` and `src/`, the layout
  abapGit's offline import takes) and `abap-cloud-gui-X.Y.Z-702.zip` (the
  same, downported to 7.02 with abaplint, as `npm run check:702` does);
- creates the GitHub release with the CHANGELOG section as its text and the
  two zips attached.

## After the release

- The documentation (abap2UI5/docs): the preview notes of report2cloud and
  `migrate_report` go - `advanced/report_migration.md`,
  `advanced/mcp_server.md`, `resources/addons.md`.
- The roadmap item of the release in README.md is ticked.

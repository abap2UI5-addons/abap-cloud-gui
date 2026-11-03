# Contributing

Write abap2UI5 apps like classic reports: selection screen, WRITE list, ALV.

## Before you open a pull request

Run what CI runs:

```sh
npm ci
npm run check
```

`npm run check` is the set of steps the workflows run on a pull request, so a
green run locally is a green run there.

## What the gates are

| Gate | What it proves |
| --- | --- |
| `npm run lint` | abaplint for Standard ABAP 7.50 |
| `npm run check:cloud`, `npm run check:702` | abaplint for ABAP Cloud and the 7.02 downport |
| `npm run check:abap2ui5` | the [abap2UI5-linter](https://github.com/abap2UI5/linter) over the classes and their views |
| `npm run check:regex` | the regular expressions of the converter |
| `npm run rename` | the namespace rename still works |
| `npm run test:report2ui5` | the report2UI5 converter tests (`:runtime` and `:browser` run the converted reports) |
| `npm run unit` | the ABAP Unit tests in the transpiled backend (needs abap2UI5/mcp-server beside this repository) |

A change to a public class of `src/01` is semantic-versioned (CHANGELOG.md, `## Unreleased`).

## Conventions

English for code, comments, commit messages and pull requests. Commit subjects
are written in the imperative and describe the outcome, not the mechanics. One
topic per pull request. The wider rules the whole ecosystem follows live in
[abap2UI5's CONVENTIONS.md](https://github.com/abap2UI5/abap2UI5/blob/main/.github/shared/CONVENTIONS.md).

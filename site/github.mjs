// Reports from GitHub for the playground (site/playground.mjs): a link
// understood, a file read from raw.githubusercontent.com, the report files
// of a folder found with the GitHub API (without a login: 60 requests an
// hour) and read from raw. Both answer cross-origin requests, so the
// browser reads straight from GitHub - nothing goes anywhere else.

const GITHUB_API = "https://api.github.com";
const GITHUB_RAW = "https://raw.githubusercontent.com";
// a folder is read whole - more files than this are not fetched
const MAX_FILES = 400;

/** what a GitHub link points to: { owner, repo, ref, path, file } - file
 *  true for a blob or a raw link; ref and path may be empty (the default
 *  branch, the whole repository). Answers undefined for no GitHub link. */
export function parseGithub(input) {
  const text = input.trim().replace(/[?#].*$/, "").replace(/\/+$/, "").replace(/\.git$/, "");
  const short = /^([\w.-]+)\/([\w.-]+)$/.exec(text);
  if (short) return { owner: short[1], repo: short[2], ref: "", path: "", file: false };
  let url;
  try {
    url = new URL(/^https?:\/\//.test(text) ? text : `https://${text}`);
  } catch {
    return undefined;
  }
  const parts = url.pathname.split("/").filter(Boolean).map(decodeURIComponent);
  if (url.hostname === "raw.githubusercontent.com" && parts.length >= 4) {
    return { owner: parts[0], repo: parts[1], ref: parts[2], path: parts.slice(3).join("/"), file: true };
  }
  if (!/^(www\.)?github\.com$/.test(url.hostname) || parts.length < 2) return undefined;
  const [owner, repo, kind, ref = "", ...rest] = parts;
  if (kind === "blob" && ref && rest.length) return { owner, repo, ref, path: rest.join("/"), file: true };
  if (kind === "tree" && ref) return { owner, repo, ref, path: rest.join("/"), file: false };
  if (kind === undefined) return { owner, repo, ref: "", path: "", file: false };
  return undefined;
}

export const rawUrl = ({ owner, repo, ref }, path) => `${GITHUB_RAW}/${owner}/${repo}/${encodeURIComponent(ref)}/${path.split("/").map(encodeURIComponent).join("/")}`;

export async function getText(url) {
  const r = await fetch(url);
  if (r.status === 404) return undefined;
  if (!r.ok) throw new Error(`${url}: ${r.status}`);
  return (await r.text()).replace(/^﻿/, "");
}

async function getJson(url) {
  const r = await fetch(url, { headers: { accept: "application/vnd.github+json" } });
  if (r.status === 403 || r.status === 429) throw new Error("GitHub's limit for requests without a login is reached - try again in an hour, or download the folder as a zip and drop it under A whole package.");
  if (r.status === 404) throw new Error("Not found on GitHub - is the repository public, and the branch and path right?");
  if (!r.ok) throw new Error(`GitHub answered ${r.status}`);
  return r.json();
}

/** the .prog.abap and .prog.xml files of a folder of a repository, as {
 *  path: text } - the tree from the GitHub API, the files from raw */
export async function folderFiles(at, onProgress) {
  const ref = at.ref || (await getJson(`${GITHUB_API}/repos/${at.owner}/${at.repo}`)).default_branch;
  const tree = await getJson(`${GITHUB_API}/repos/${at.owner}/${at.repo}/git/trees/${encodeURIComponent(ref)}?recursive=1`);
  const prefix = at.path ? `${at.path}/` : "";
  const paths = tree.tree
    .filter((x) => x.type === "blob" && x.path.startsWith(prefix) && /\.prog\.(abap|xml)$/i.test(x.path))
    .map((x) => x.path);
  if (paths.length > MAX_FILES) throw new Error(`${paths.length} report files there - more than ${MAX_FILES}; link a folder further down.`);
  const files = {};
  let done = 0;
  const next = [...paths];
  const worker = async () => {
    for (let path = next.shift(); path; path = next.shift()) {
      const text = await getText(rawUrl({ ...at, ref }, path));
      if (text !== undefined) files[path] = text;
      onProgress(++done, paths.length);
    }
  };
  await Promise.all(Array.from({ length: 8 }, worker));
  return { files, ref, truncated: tree.truncated };
}

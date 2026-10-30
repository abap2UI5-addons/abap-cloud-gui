// Reading a zip in the browser - the abapGit zip of a package a user drops
// on the site. The central directory names the entries, each one stored or
// deflated; a deflated entry is inflated with the DecompressionStream the
// browser has. Answers the text files as { path: text }; folders and what
// is not UTF-8 text are left out. No library: the format is forty lines.

const SIG_CENTRAL = 0x02014b50;
const SIG_END = 0x06054b50;

async function inflate(bytes) {
  const stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream("deflate-raw"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

/** the entries of a zip: [{ path, bytes }] */
export async function unzipEntries(buffer) {
  const bytes = buffer instanceof Uint8Array ? buffer : new Uint8Array(buffer);
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  // the end record, from the back - a comment may follow it
  let end = -1;
  for (let i = bytes.length - 22; i >= Math.max(0, bytes.length - 22 - 0xffff); i--) {
    if (view.getUint32(i, true) === SIG_END) {
      end = i;
      break;
    }
  }
  if (end < 0) throw new Error("not a zip file");
  const count = view.getUint16(end + 10, true);
  let at = view.getUint32(end + 16, true);
  const dec = new TextDecoder("utf-8", { fatal: true });
  const out = [];
  for (let n = 0; n < count; n++) {
    if (view.getUint32(at, true) !== SIG_CENTRAL) throw new Error("a damaged zip file");
    const method = view.getUint16(at + 10, true);
    const compressed = view.getUint32(at + 20, true);
    const nameLen = view.getUint16(at + 28, true);
    const extraLen = view.getUint16(at + 30, true);
    const commentLen = view.getUint16(at + 32, true);
    const local = view.getUint32(at + 42, true);
    const path = dec.decode(bytes.subarray(at + 46, at + 46 + nameLen));
    at += 46 + nameLen + extraLen + commentLen;
    if (path.endsWith("/")) continue;
    const localName = view.getUint16(local + 26, true);
    const localExtra = view.getUint16(local + 28, true);
    const start = local + 30 + localName + localExtra;
    const data = bytes.subarray(start, start + compressed);
    if (method === 0) out.push({ path, bytes: data });
    else if (method === 8) out.push({ path, bytes: await inflate(data) });
    else throw new Error(`${path}: a compression this reader does not know (${method})`);
  }
  return out;
}

/** the text files of a zip as { path: text } - the others left out */
export async function unzipTexts(buffer) {
  const dec = new TextDecoder("utf-8", { fatal: true });
  const out = {};
  for (const { path, bytes } of await unzipEntries(buffer)) {
    try {
      out[path] = dec.decode(bytes).replace(/^﻿/, "");
    } catch {
      // binary - not a source file
    }
  }
  return out;
}

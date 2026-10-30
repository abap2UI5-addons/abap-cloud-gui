// The include reader over folders: includesFrom( dirs ) answers an include
// by its name from the first folder that has its file - what the CLI, the
// coverage and the package run hand inlineIncludes( ) of includes.mjs,
// which itself reads nothing from disk (the site bundles it).
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { includeFileName } from "./includes.mjs";

/** a `read( )` over folders of abapGit files, the first that has the include wins */
export function includesFrom(dirs) {
  return (name) => {
    for (const dir of dirs) {
      const path = join(dir, includeFileName(name));
      if (existsSync(path)) return readFileSync(path, "utf8");
    }
    return undefined;
  };
}

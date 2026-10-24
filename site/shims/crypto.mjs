// The node:crypto of the browser bundle - abaplint's downport rule hashes a
// name with it, which the converter never runs; it is there to resolve
export function createHash() {
  throw new Error("crypto.createHash is not available in the browser");
}
export default { createHash };

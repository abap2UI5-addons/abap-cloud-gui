// The Buffer of the browser bundle - abaplint's built-in constants
// (%_MAXCHAR, %_MINCHAR) are made with Buffer.from(hex).toString(); that is
// all of Buffer the converter reaches
const hex = (text) => new Uint8Array((text.match(/../g) ?? []).map((b) => parseInt(b, 16)));

export const Buffer = {
  from(value, encoding) {
    const bytes = encoding === "hex" ? hex(String(value)) : new TextEncoder().encode(String(value));
    return { toString: () => new TextDecoder().decode(bytes) };
  },
};

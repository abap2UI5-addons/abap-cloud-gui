// The rows the runtime test seeds into the stubs of test/ddic, and the
// messages of the message class ZR2C the corpus reports use (T100 is part of
// the runtime's schema). Flight dates are relative to today, because
// zr2c_02_flights selects from today to today + 90 by default.
//
// The expectations of runtime.test.mjs are written by hand from these rows:
// what the classic report prints for them.

/** YYYYMMDD of today + `days`, in the local time zone (sy-datum's). */
export function dateIn(days, now = new Date()) {
  const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + days);
  return `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, "0")}${String(d.getDate()).padStart(2, "0")}`;
}

/** YYYY-MM-DD, as a date reaches the model and the list */
export const iso = (yyyymmdd) => `${yyyymmdd.slice(0, 4)}-${yyyymmdd.slice(4, 6)}-${yyyymmdd.slice(6, 8)}`;

export const SCARR = [
  { carrid: "AA", carrname: "American Airlines", currcode: "USD", url: "http://www.aa.com" },
  { carrid: "LH", carrname: "Lufthansa", currcode: "EUR", url: "http://www.lufthansa.com" },
  { carrid: "SQ", carrname: "Singapore Airlines", currcode: "SGD", url: "http://www.singaporeair.com" },
];

export const SPFLI = [
  { carrid: "LH", connid: "0400", countryfr: "DE", cityfrom: "FRANKFURT", airpfrom: "FRA", countryto: "US", cityto: "NEW YORK", airpto: "JFK", fltime: 444, deptime: "101000", arrtime: "113400" },
  { carrid: "LH", connid: "0402", countryfr: "DE", cityfrom: "FRANKFURT", airpfrom: "FRA", countryto: "US", cityto: "NEW YORK", airpto: "JFK", fltime: 455, deptime: "133000", arrtime: "150500" },
  { carrid: "LH", connid: "2402", countryfr: "DE", cityfrom: "BERLIN", airpfrom: "TXL", countryto: "DE", cityto: "FRANKFURT", airpto: "FRA", fltime: 65, deptime: "103000", arrtime: "113500" },
  { carrid: "AA", connid: "0017", countryfr: "US", cityfrom: "NEW YORK", airpfrom: "JFK", countryto: "US", cityto: "SAN FRANCISCO", airpto: "SFO", fltime: 361, deptime: "110000", arrtime: "140100" },
];

/** today-relative dates: two inside the default range of zr2c_02, one before
 *  it, one after it, and one flight of another airline */
export function sflight(now = new Date()) {
  return [
    { carrid: "LH", connid: "0400", fldate: dateIn(10, now), price: "666.00", currency: "EUR", planetype: "A340-600", seatsmax: 330, seatsocc: 120 },
    { carrid: "LH", connid: "0402", fldate: dateIn(30, now), price: "777.50", currency: "EUR", planetype: "747-400", seatsmax: 385, seatsocc: 385 },
    { carrid: "LH", connid: "0400", fldate: dateIn(-20, now), price: "555.00", currency: "EUR", planetype: "A340-600", seatsmax: 330, seatsocc: 300 },
    { carrid: "LH", connid: "2402", fldate: dateIn(200, now), price: "99.00", currency: "EUR", planetype: "A321", seatsmax: 200, seatsocc: 10 },
    { carrid: "AA", connid: "0017", fldate: dateIn(15, now), price: "422.94", currency: "USD", planetype: "747-400", seatsmax: 385, seatsocc: 371 },
  ];
}

/** the message class of the corpus (MESSAGE-ID zr2c) */
export const T100 = [
  { msgnr: "001", text: "At most 1000 rows, not &1" },
  { msgnr: "002", text: "No flights of airline &1" },
  { msgnr: "003", text: "Flight &1 &2: &3 seats occupied" },
  { msgnr: "010", text: "Message type &1 is not S, I, W or E" },
  { msgnr: "011", text: "&1 &2" },
  { msgnr: "012", text: "Number &1 is a warning" },
  { msgnr: "013", text: "Number &1 processed" },
];

const quote = (v) => (typeof v === "number" ? String(v) : `'${String(v).replace(/'/g, "''")}'`);

function inserts(table, rows, extra = {}) {
  return rows.map((r) => {
    const row = { ...extra, ...r };
    return `INSERT INTO '${table}' (${Object.keys(row).map((k) => `'${k}'`).join(", ")}) VALUES (${Object.values(row).map(quote).join(", ")});`;
  });
}

/** the SQL the boot runs after the tables exist */
export function seedSql(now = new Date()) {
  return [
    ...inserts("scarr", SCARR, { mandt: "000" }),
    ...inserts("spfli", SPFLI, { mandt: "000" }),
    ...inserts("sflight", sflight(now), { mandt: "000" }),
    ...inserts("t100", T100.map((m) => ({ sprsl: "E", arbgb: "ZR2C", ...m }))),
  ];
}

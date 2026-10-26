// The released successors of classic tables whose columns map one to one -
// the tables of the flight model onto the ABAP Flight Reference Scenario,
// and a few of the S/4HANA core onto their released CDS views. A SELECT of
// one of them is rewritten only when every column it names has a
// counterpart here: the new table, the new columns under the old names (AS),
// so the target of INTO stays as it is. Every old table has a column more
// than the new one has, so SELECT * stays as it is.

export const SUCCESSOR_TABLES = {
  scarr: {
    name: "/dmo/carrier",
    columns: { carrid: "carrier_id", carrname: "name", currcode: "currency_code" },
  },
  spfli: {
    name: "/dmo/connection",
    columns: { carrid: "carrier_id", connid: "connection_id", airpfrom: "airport_from_id", airpto: "airport_to_id",
      deptime: "departure_time", arrtime: "arrival_time", distance: "distance", distid: "distance_unit" },
  },
  sflight: {
    name: "/dmo/flight",
    columns: { carrid: "carrier_id", connid: "connection_id", fldate: "flight_date", price: "price", currency: "currency_code",
      planetype: "plane_type_id", seatsmax: "seats_max", seatsocc: "seats_occupied" },
  },
  sbook: {
    name: "/dmo/booking",
    columns: { carrid: "carrier_id", connid: "connection_id", fldate: "flight_date", bookid: "booking_id",
      customid: "customer_id", order_date: "booking_date" },
  },
  scustom: {
    name: "/dmo/customer",
    columns: { id: "customer_id", street: "street", postcode: "postal_code", city: "city", country: "country_code",
      telephone: "phone_number", email: "email_address" },
  },
  t005t: {
    name: "i_countrytext",
    columns: { spras: "language", land1: "country", landx: "countryname" },
  },
  t001: {
    name: "i_companycode",
    columns: { bukrs: "companycode", butxt: "companycodename", land1: "country", waers: "currency", ort01: "cityname" },
  },
  makt: {
    name: "i_productdescription",
    columns: { matnr: "product", spras: "language", maktx: "productdescription" },
  },
};
Object.setPrototypeOf(SUCCESSOR_TABLES, null);

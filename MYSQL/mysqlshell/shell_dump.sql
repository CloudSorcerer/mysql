-- Full DB - Tables + data + views + triggers + routines + events

util.dumpSchemas(
  ["db_alpha"],
  "/backup/db_alpha",
  {
    consistent: true,
    threads: 4,
    compatibility: ["strip_definers"]
  }
);

-- Restore DB

util.loadDump("/backup/db_alpha", {
  ignoreVersion: true,
  deferTableIndexes: "all"
});
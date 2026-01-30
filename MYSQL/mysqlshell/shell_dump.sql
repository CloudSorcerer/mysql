-- 

util.dumpSchemas(
  ["db_alpha"],
  "/backup/db_alpha",
  {
    consistent: true,
    threads: 4,
    compatibility: ["strip_definers"]
  }
);


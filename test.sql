-- FULL BACKUP — ALL databases - JS
-- Threads: 25% (live prod) / 50% (non-prod) / 75% (night/maintenance)
util.dumpInstance("/backup/full_instance_all", {
  threads: 4,           
  showProgress: true,  
  consistent: true, 
  users: true,         
  events: true,         
  routines: true,     
  triggers: true    
});

==========================================================================================
-- FULL BACKUP — ONE database (example: db_alpha) - JS
-- Threads: 25% (live prod) / 50% (non-prod) / 75% (night/maintenance)
util.dumpSchemas(
  ["db_alpha"],
  "/backup/db_alpha_full",
  {
    threads: 4,
    showProgress: true,
    consistent: true,
    routines: true,
    triggers: true,
    events: true
  }
);

==========================================================================================
-- TABLES ONLY (structure + data) — NO views, routines, triggers, - JS
-- Threads: 25% (live prod) / 50% (non-prod) / 75% (night/maintenance)
util.dumpSchemas(
  ["db_alpha"],
  "/backup/db_alpha_tables_data_only",
  {
    threads: 4,
    showProgress: true,
    consistent: true,
    routines: false,
    triggers: false,
    events: false
  }
);

==========================================================================================
-- TABLE STRUCTURE ONLY — NO data, NO views, NO routines, NO triggers, NO events - JS
-- Threads: 25% (live prod) / 50% (non-prod) / 75% (night/maintenance)
util.dumpSchemas(
  ["db_alpha"],
  "/backup/db_alpha_tables_structure_only",
  {
    ddlOnly: true,
    routines: false,
    triggers: false,
    events: false
  }
);


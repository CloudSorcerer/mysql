##################################### 🔹 SHOW Definer #################################################

========================================================================================================

-- Show DEFINERS for all  **.sql files**

grep -Hn "DEFINER=" /backup/*.sql

========================================================================================================

-- Show definers for specific file 

grep -Hn "DEFINER=" /backup/db.sql

========================================================================================================

-- Per-file mapping (BEST VIEW) - How many Definers have file


for f in /backup/*.sql; do
  definers=$(grep -oE 'DEFINER=`[^`]+`@`[^`]+' "$f" \
    | sed 's/DEFINER=`//;s/`@`/@/' \
    | sort -u | tr '\n' ' ')
  printf "%-40s : %s\n" "$(basename "$f")" "${definers:-none}"
done

========================================================================================================
-- Count how many objects each DEFINER owns (very useful)


grep -H "DEFINER=" /backup/*.sql \
| sed -E 's/.*DEFINER=`([^`]*)`@`([^`]*)`.*/\1@\2/' \
| sort | uniq -c | sort -nr

========================================================================================================


##################################### 🔹 SED - Changing Definer #######################################

========================================================================================================

-- Change Definer - SAFE WAY (Recommended): create a NEW file


sed 's/DEFINER=`[^`]*`@`[^`]*`/DEFINER=`user1`@`%`/g' \
/backup/event.sql \
> /new_event.sql

========================================================================================================

-- Change one definer with other


sed 's/DEFINER=`user1`@`[^`]*`/DEFINER=`user2`@`%`/g' /backup/test_event.sql > /test_even1.sql

========================================================================================================

-- DRY-RUN / PREVIEW


sed -n 's/DEFINER=`user1`@`[^`]*`/DEFINER=`user2`@`%`/p' /backup/test_event.sql > /test_event.sql

========================================================================================================

-- Change Definer  - In-place (Not Recommended)


sed -i 's/DEFINER=`[^`]*`@`[^`]*`/DEFINER=`user1`@`%`/g' file.sql

========================================================================================================
-- Change 1 definer with another  (Not Recommended)


sed -i 's/DEFINER=`user1`@`[^`]*`/DEFINER=`user2`@`%`/g' /test_event1.sql
========================================================================================================

-- SHOW lines in a files

sed -n '1110,1330p' /backup/db_name_full_2026-01-26_13-00-54.sql


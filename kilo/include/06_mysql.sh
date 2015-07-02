exec_mysql_query() {
  QUERY=$*
  QUERY_FILE=$PWD/.sql

  if [ ! -z $DB_USER ] && [ ! -z $DB_PASS ] && [ ! -z $DB_HOST ] && [ ! -z $DB ]; then
    echo $QUERY > $QUERY_FILE
    rs=`mysql -u $DB_USER -p$DB_PASS -h $DB_HOST $DB < $QUERY_FILE | awk '{if (NR!=1){print}}'`
  else
    echo "ERROR: DB= $DB DB_HOST= $DB_HOST DB_USER= $DB_USER DB_PASS= $DB_PASS"
  fi

  eval "RSET=$rs"
}

exec_mysql_query_admin() {
  QUERY=$*
  QUERY_FILE=$PWD/.sql

  if [ ! -z $DB_ADM_USER ] && [ ! -z $DB_ADM_PASS ] && [ ! -z $DB_HOST ] && [ ! -z $ADM_DB ]; then
    echo $QUERY > $QUERY_FILE
    rs=`mysql -u $DB_ADM_USER -p$DB_ADM_PASS -h $DB_HOST $ADM_DB < $QUERY_FILE | awk '{if (NR!=1){print}}'`
  else
    echo "ERROR: DB= $ADM_DB DB_HOST= $DB_HOST DB_USER= $DB_ADM_USER DB_PASS= $DB_ADM_PASS"
  fi

  eval "RSET=$rs"
}

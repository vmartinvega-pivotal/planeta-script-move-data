#!/bin/bash

while [ "$1" != "" ]; do
    case $1 in
        -s | --source )         shift
                                SOURCE_DATABASE=$1
                                ;;
        -d | --destination )    DESTINATION_DATABASE=$2
				;;
        -i | --input )          INPUT_FILE=$2
                                ;;
        -h | --help )           echo 'Please provide source database -s, destination database -d and input file -i'
                                exit
                                ;;
        * )
    esac
    shift
done

function toLowerCase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

echo "Script parameters"
echo ""
echo "source database: $SOURCE_DATABASE"
echo "destiny database: $DESTINATION_DATABASE"
echo "input file: $INPUT_FILE"
echo ""

# If log level is not set it is initialized as INFO
if [[ ! -v script_logging_level ]] || [[ -z "$script_logging_level" ]]; then
  export script_logging_level="INFO"
fi

# Source utils
echo "Sourcing files..."
echo ""
source log-utils.sh

# Init log file
initLogs

TEMP_RANDOM_FILE="/home/gpadmin/borrar_file"

while IFS= read -r line
do
  source_sentence=$(cut -d'|' -f1 <<< $line)
  destination_table=$(cut -d'|' -f2 <<< $line)
  final_sentence=$(cut -d'|' -f3 <<< $line)
  truncate=$(cut -d'|' -f4 <<< $line)
  truncate=$(toLowerCase $truncate)  

  logMessage "Source Greenplum sentence: $source_sentence" "DEBUG"
  logMessage "Destination Greenplum table: $destination_table" "DEBUG"
  logMessage "Final Greenplum sentence: $final_sentence" "DEBUG"

  echo ""
  logMessage "Executing sentences..." "INFO"
  echo ""
  logMessage "Reading data from source sentence: $source_sentence" "INFO"
  rm -f ${TEMP_RANDOM_FILE}
  psql -d $SOURCE_DATABASE -c "COPY (${source_sentence}) TO '${TEMP_RANDOM_FILE}'" >> /dev/null 2>&1
  if [ $? -eq 0 ]
  then
    if [[ $truncate = "true" ]]
    then
      logMessage "Truncating database table: $destination_table" "INFO"
      psql -d $DESTINATION_DATABASE -c "TRUNCATE $destination_table"
      logMessage "Vacuuming database table: $destination_table" "DEBUG"
      psql -d $DESTINATION_DATABASE -c "VACUUM $destination_table"
    fi
    logMessage "Inserting data in destination database table: $destination_table" "INFO"
    psql -d $DESTINATION_DATABASE -c "COPY $destination_table FROM '${TEMP_RANDOM_FILE}'" >> /dev/null 2>&1
    if [ $? -eq 0 ]
    then
      logMessage "Executing final sentence in destination database: $DESTINATION_DATABASE" "INFO"
      psql -d $DESTINATION_DATABASE -c "$final_sentence" >> /dev/null 2>&1
      if [ $? -eq 0 ]
      then
        logMessage "Moved successfully the data!" "INFO"
      else
        logMessage "Error executing final sentence: $final_sentence" "ERROR"
      fi
    else
      logMessage "Error inserting  data to destination database: $DESTINATION_DATABASE and table: $sdestination_table" "ERROR"
    fi
  else
    logMessage "Error getting data from source database: $SOURCE_DATABASE and sentence: $source_sentence" "ERROR"
  fi
done < "$INPUT_FILE"

#!/bin/bash

################################ SCRIPT ################################

set -e

help() {
    echo
    echo "This script will export the results of a bean-query to a csv file."
    echo
    echo "Usage: $0 [ -q QUERY_FILE ] [ -s START_DATE ] [ -e END_DATE ]"
    echo "options:"
    echo "a     Specify a single account for the query"
    echo "s     Specify the query_file (do not include the full directory path)"
    echo "s     Specify the start date for the query"
    echo "e     Specify the end date for the query"
    echo "h     Print this Help menu"
    echo
}
exit_abnormal() {
    help
    exit 1
}
while getopts ":q:a:s:e:" flag
do
    case ${flag} in
        q) QUERY_FILE=${OPTARG} ;;
        a) ACCOUNT=${OPTARG} ;;
        s) START_DATE=${OPTARG} ;;
        e) END_DATE=${OPTARG} ;;
        h) exit_abnormal ;;
        *) exit_abnormal ;;
    esac
done

BEAN_DIR="/mnt/pointer/Ledger"

if [ ! ${QUERY_FILE} ]; then
    echo "ERROR: no query file specified"
    exit_abnormal
fi

QUERY="$(<${BEAN_DIR}/queries/${QUERY_FILE})"

if [[ ${QUERY} = *"_date }}"* ]]; then
    if [ ! ${START_DATE} ]; then
        if (( $(date +%m) >= 7 )); then
            START_DATE=$(date +%Y)-07-01
        else
            START_DATE=$(date +%Y -d '-1 year')-07-01
        fi
    elif ! date -d ${START_DATE} &> /dev/null; then
        echo "ERROR: start_date is not valid"
        exit_abnormal
    fi

    if [ ! ${END_DATE} ]; then
        if (( $(date +%m) >= 7 )); then
            END_DATE=$(date +%Y -d '1 year')-06-30
        else
            END_DATE=$(date +%Y)-06-30
        fi
    elif ! date -d ${END_DATE} &> /dev/null; then
        echo "ERROR: end_date is not valid"
        exit_abnormal
    fi

    QUERY="${QUERY/'{{ start_date }}'/"${START_DATE}"}"
    QUERY="${QUERY/'{{ end_date }}'/"${END_DATE}"}"
    FILENAME=${END_DATE}_${QUERY_FILE}
elif [[ ${QUERY} = *"{{ account }}"* ]]; then
    QUERY="${QUERY/'{{ account }}'/"${ACCOUNT}"}"
    FILENAME=${ACCOUNT/:/-}_${QUERY_FILE}
    MARK="1"
else
    FILENAME=${QUERY_FILE}
fi

echo "Running query:"
echo ${QUERY}
docker exec fava bean-query /bean/data/master.beancount ${QUERY} -f csv -o "/bean/data/queries/output/${FILENAME}.csv"

sudo chown 1000:1000 "${BEAN_DIR}/queries/output/${FILENAME}.csv"

sed -i 's/ //g' "${BEAN_DIR}/queries/output/${FILENAME}.csv"

if [[ ${MARK} == "1" ]]; then
    sed -i 's/AUD//g' "${BEAN_DIR}/queries/output/${FILENAME}.csv"
fi

echo "Query exported."
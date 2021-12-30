#!/bin/bash

################################ SCRIPT ################################

set -e

if [ ! -d ${HOME}/scripts/csv2excel/ ]; then
    git clone https://github.com/kstockk/csv2excel.git ${HOME}/scripts/csv2excel
    cd ${HOME}/scripts/csv2excel
    python3 -m venv venv
    source venv/bin/activate && pip install -r requirements.txt
fi

cd ${HOME}/scripts/csv2excel
source venv/bin/activate

# Get End Date of Current FY
if (( $(date +%m) >= 7 )); then
    END_YEAR=$(date +%Y -d '1 year')
else
    END_YEAR=$(date +%Y)
fi
END_DATE=${END_YEAR}-06-30

BEAN_DIR="/mnt/pointer/Ledger"
CSV_FILE="${END_DATE}_is_monthly_bals.csv"
BUDGET="Budget ${END_YEAR}.xlsx"
WS="Transactions"

if [ -f ${BEAN_DIR}/budget/${BUDGET} ] then
    python main.py "${BEAN_DIR}/queries/output/${CSV_FILE}" "${BEAN_DIR}/budget/${BUDGET}" "${WS}"

    echo "Budget transactions updated."
else
    echo "${BEAN_DIR}/budget/${BUDGET} not found."
fi
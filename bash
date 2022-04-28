#!/bin/bash

#Date of Report
echo -e "Status Log for $(date)\n" >> compliance_report.log

#Check status of PermitRootLogin
PRL1=$(cat /etc/ssh/sshd_config | grep -m1 PermitRootLogin)
PRLN="PermitRootLogin no"

if [ "$PRL1" = "$PRLN" ]; 
    then
        echo -e "COMPLIANT: PermitRootLogin status is OK.\n" >> compliance_report.log
    else
        echo -e "NON-COMPLIANT:\nCurrent PermitRootLogin status: $PRL1\n" | tee -a compliance_report.log compliance_ERROR.log
fi

#Check status of PermitEmptyPasswords
PEP1=$(cat /etc/ssh/sshd_config | grep -m1 PermitEmptyPasswords)
PEPN="PermitEmptyPasswords no"

if [ "$PEP1" = "$PEPN" ]; 
    then
        echo -e "COMPLIANT: PermitEmptyPasswords status is OK.\n" >> compliance_report.log
    else
        echo -e "NON-COMPLIANT:\nCurrent PermitEmptyPasswords status: $PRL1\n" | tee -a compliance_report.log compliance_ERROR.log
fi

#Check if Protocol 2 exists
P21=$(grep -xF 'Protocol 2' /etc/ssh/sshd_config)
P2N="Protocol 2"

if [ "$P21" = "$P2N" ]; 
    then
        echo -e "COMPLIANT: Protocol 2 is enabled.\n" >> compliance_report.log
    else
        echo -e "NON-COMPLIANT: Protocol 2 not supported\n" | tee -a compliance_report.log compliance_ERROR.log
fi

#Check PASS_MAX_DAYS
PWE1=$(grep PASS_MAX_DAYS /etc/login.defs | tail -n1 | grep -o '[[:digit:]]*')

if [ "$PWE1" -le "90" ]; 
    then
        echo -e "COMPLIANT: PASS_MAX_DAYS status is OK.\n" >> compliance_report.log
    else
        echo -e "NON-COMPLIANT: PASS_MAX_DAYS status is more than 90.\nCurrent status: PASS_MAX_DAYS    $PWE1\n" | tee -a compliance_report.log compliance_ERROR.log
fi

## Check User Non-login Status

getent passwd | awk -F ':' '$3>1 && $3<1000' > shellerror.log 

USX=$(cat shellerror.log | grep -v 'nologin')

grep -v 'nologin' shellerror.log > /dev/null

if [ $? = 0 ]
    then
        echo -e "NON-COMPLIANT: System accounts login shell is not secured.\nCurrent system accounts shell:\n$USX\n" | tee -a compliance_report.log >> compliance_ERROR.log
    else
        echo -e "COMPLIANT: System accounts shell login is OK.\n" >> compliance_report.log
fi


#Send email to alert admin if there are any errors 
subject="Status Alert $(date)"
to="hohuisian.footage@gmail.com"

cat compliance_ERROR.log  > /dev/null 2>&1

if [ $? = 0 ]
    then
        cat compliance_ERROR.log | mailx -s "$subject" "$to" 
    else
        cat compliance_ERROR.log > /dev/null 
fi

rm -f shellerror.log
rm -f compliance_ERROR.log

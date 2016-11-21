#!/bin/bash
# Author: Muhamed Hamid (lORD OF WAR)
# Advanced Check per Domain
# Created on 4/12/2015

#Pull color code script
eval "$(curl -s http://162.221.188.99/colors)";

clear;

echo ""
if [ -z $1 ]; then

    echo -e "\n$H1===========$H2 Account and Domain Checker$H1===========$RS";
    echo ""
    echo -e "$BOLD "
    read -p  "Please enter a DOMAIN name or cPanel username: " INPUTZ; echo -e "$RS"
else
    INPUTZ=$1
fi

echo ""
CHECKDOMAIN=$(echo $INPUTZ | grep -s "\.");

if [[ -z $CHECKDOMAIN ]];then

        CHECKACCOUNT=$(cat /etc/trueuserdomains | cut -f2 -d' ' | grep -s "^$INPUTZ$");
        if [[ -z $CHECKACCOUNT ]]; then
                echo "This account does not exist, loser!";
        kill $$;
        
        else
        THEDOMAIN=$(grep -w $INPUTZ /etc/trueuserdomains | cut -d: -f1);
        THEACCOUNT=$(/scripts/whoowns "$THEDOMAIN");
        fi
else
        CHECKDOMAIN=$(grep "^$INPUTZ:" /etc/userdomains | grep -v ": nobody$")
        if [[ -z "$CHECKDOMAIN" ]];then
                echo "This domain does not exist"
        kill $$;
      
        else
        THEDOMAIN=$INPUTZ;
        THEACCOUNT=$(/scripts/whoowns "$INPUTZ");
        fi
fi

echo -e "\n$H1===========$H2 Basic Information $H1===========$RS";
echo -e "$Y1 THE ACCOUNT name is: $W1 $THEACCOUNT $RS";
echo -e "$Y1 THE DOMAIN name is: $W1 $THEDOMAIN $RS";

echo -e "\n$SH1=-=-=-=-=$SH2 Addon or Parked Domains $SH1=-=-=-=-=$RS";
linenum=$(grep -n sub_domains: /var/cpanel/userdata/$THEACCOUNT/main | cut -f1 -d ':');
linenum=$((linenum-1));
head -$linenum /var/cpanel/userdata/$THEACCOUNT/main | grep -v main_domain: | awk '{print $1}' | cut -f1 -d:;

echo -e "\n$H1===========$H2 Accounting Log $H1===========$RS";
grep -w $THEACCOUNT /var/cpanel/accounting.log

echo -e "\n$H1===========$H2 Backups $H1===========$RS";
echo -e "$W1 Legacy Backups: $RS"
if [[ -f /etc/cpbackup-userskip.conf ]]; then
  userskip=$(grep -w $THEACCOUNT /etc/cpbackup-userskip.conf)
fi
if [[ -z $userskip ]]; then
  ls -ho /backup/cpbackup/*/"$THEACCOUNT"/version 2> /dev/null
else
  echo -e "$Y1 The account $W1 $THEACCOUNT $Y1 is listed in /etc/cpbackup-userskip.conf $RS";
  ls -ho /backup/cpbackup/*/"$THEACCOUNT"/version 2> /dev/null
fi

echo -e "\n$W1 New Backups: $RS";
flag=$(ls -ho /backup/*/accounts/$THEACCOUNT* 2> /dev/null | awk '{print $8}' | head -1);
if [[ -f $flag ]]
then
    ls -ho /backup/*/accounts/$THEACCOUNT* | awk '{print $4,$5,$6,$7,$8}';
else
    flag2=$(ls -ho /backup/*/*/accounts/$THEACCOUNT* 2> /dev/null | awk '{print $8}' | head -1);
    if [[ -f $flag2 ]]; then
        ls -ho /backup/*/*/accounts/$THEACCOUNT* | awk '{print $4,$5,$6,$7,$8}';
else
## Checks if the backups are incrememntal and then checks the most recent change
             if [[ -d "/backup/incremental/accounts/$THEACCOUNT/" ]]; then
                BackupDate=$(stat /backup/incremental/accounts/$THEACCOUNT/ | awk 'FNR == 6 {print $2}');
                echo "Using incremental backups. Most Recent update: $BackupDate"
else
     echo -e "$Y1 Not using New Backups $RS"
    fi
  fi
fi

echo -e "\n$H1===========$H2 Package Information $H1===========$RS";
grepip=$(grep IP /var/cpanel/users/$THEACCOUNT | cut -c4-)
digip=$(dig @8.8.8.8 +short A $THEDOMAIN)
echo "Currently pointed to:" $digip
if [[ "$grepip" == "$digip" ]]
then
        echo -e "$G1 This domain is pointed to the correct IP $RS"
else
        echo -e "$R1 WARNING: This domain either does not point to the server or the correct IP $RS"
fi
grep OWNER /var/cpanel/users/$THEACCOUNT | grep -v DBOWNER
grep IP /var/cpanel/users/$THEACCOUNT
grep PLAN /var/cpanel/users/$THEACCOUNT
grep MAX /var/cpanel/users/$THEACCOUNT | grep -v EMAIL | grep -v LST | grep -v SQL | grep -v POP | grep -v DEFER | grep -v SUB | grep -v FTP

echo -e "\n$H1===========$H2 Account Disk Usage $H1===========$RS";
echo -e "$CM1 #####$CM2 If this takes a while to complete it's a big account $RS"
du -sch /home/$THEACCOUNT/ | awk 'NR==1 {print $1" "$2}'
plan=$(grep PLAN /var/cpanel/users/$THEACCOUNT | cut -d = -f 2)
grep QUOTA /var/cpanel/packages/$plan

echo -e "\n$H1===========$H2 Inodes $THEACCOUNT $H1===========$RS";
#location=$(pwd)
cd /home/$THEACCOUNT/;
inodes=$(find . -maxdepth 1 -type d | while read line ; do echo "$( find "$line"| wc -l) $line" ; done |  sort -rn | head -1 | awk '{print $1}');

if [ $inodes -lt 100000 ]; then
  echo -e "Total inodes: $W1 $inodes $RS"
else
  if [ $inodes -lt 250000 ]; then
         echo -e "$Y1 $THEACCOUNT is over backup limit: $R1 $inodes $RS"
  else
        echo -e "$Y1 $THEACCOUNT is over suspension limit: $BAD $inodes $RS"
  fi
fi

if [ $inodes -ge 3720000 ]; then
  echo -e "$R1 HIGH SCORE!! $Y1 Total inodes: $W1 $inodes $RS"
fi

find . -maxdepth 1 -type d | while read line ; do echo "$( find "$line"| wc -l) $line" ; done |  sort -rn | head -5 | tail -4

echo -e "\n$H1===========$H2 Apache Error Log $H1===========$RS";
echo "If this is blank, there are no errors logged today."
month=$(date | cut -d " " -f 2)
day=$(date | cut -d " " -f 3)
today=$month" "$day

grep "$today" /etc/httpd/logs/error_log | grep $THEDOMAIN | grep -v "File does not exist" | grep -v "XML parser error" | tail -10

echo -e "\n$H1===========$H2 MySQL Errors $H1===========$RS";
echo "If this is blank, there are no errors logged today."
host=$(hostname)
host=$host.err
grep "$today" /var/lib/mysql/$host | grep $THEDOMAIN

echo -e "\n$H1===========$H2 Local Error Log $H1===========$RS";
if [ -f /home/$THEACCOUNT/public_html/error_log ]
then
        echo "If this is empty, no errors logged today."
        grep "$today" /home/$THEACCOUNT/public_html/error_log | grep $THEDOMAIN
else
        echo "Error_log does not exist."
fi

echo -e "\n$H1===========$H2 DNS: $THEDOMAIN $H1===========$RS";
echo -e "$SH1=-=-=-=$SH2 Remote Nameservers: $SH1=-=-=-= $RS"
digns=$(dig @8.8.8.8 +short NS $THEDOMAIN | tail -n2)
echo "$digns"

echo -e "$SH1=-=-=-=$SH2 Local Nameservers: $SH1=-=-=-= $RS"
grep NS /var/named/$THEDOMAIN.db

echo -e "$SH1=-=-=-=$SH2 A Records $SH1=-=-=-= $RS"
grep A /var/named/$THEDOMAIN.db | grep -v CNAME | grep -v SOA | grep -v localhost | grep -v auto | grep -v webdisk | grep -v TXT

echo -e "$SH1=-=-=-=$SH2 CNAME Records $SH1=-=-=-= $RS"
grep CNAME /var/named/$THEDOMAIN.db

echo -e "$SH1=-=-=-=$SH2 Email Records $SH1=-=-=-= $RS"
grep MX /var/named/$THEDOMAIN.db
grep SRV /var/named/$THEDOMAIN.db
grep TXT /var/named/$THEDOMAIN.db | grep -v default\.
grep PTR /var/named/$THEDOMAIN.db

echo -e "\n$H1===========$H2 PHP Information $H1===========$RS";
if [ ! -f /home/$THEACCOUNT/public_html/php.ini ]
then
        echo " Local php.ini does not exist. This is the global memory_limit:"
        grep memory_limit /usr/local/lib/php.ini
else
        grep memory_limit /home/$THEACCOUNT/public_html/php.ini
        grep max_execution_time /home/$THEACCOUNT/public_html/php.ini
        grep max_input_time /home/$THEACCOUNT/public_html/php.ini
        grep post_max_size /home/$THEACCOUNT/public_html/php.ini
        grep magic_quotes_gpc /home/$THEACCOUNT/public_html/php.ini
        grep upload_max_filesize /home/$THEACCOUNT/public_html/php.ini
        grep allow_url_fopen /home/$THEACCOUNT/public_html/php.ini
        grep date.timezone /home/$THEACCOUNT/public_html/php.ini
        grep disable_functions /home/$THEACCOUNT/public_html/php.ini
fi

echo -e "\n$H1===========$H2 .htaccess $H1===========$RS";
if [ -f /home/$THEACCOUNT/public_html/.htaccess ]
then
        grep suPHP /home/$THEACCOUNT/public_html/.htaccess
else
        echo ".htaccess does not exist."
fi

echo -e "\n$H1===========$H2 LFD Log $H1===========$RS";
echo "If this is blank, there are no errors logged today."
grep $THEDOMAIN /var/log/lfd.log | grep "Blocked in csf"

echo -e "\n$H1===========$H2 Access Logs $H1===========$RS";
   echo -e "If this is blank, there are no accesses logged today."
   tail -1000 /var/log/messages | grep $THEDOMAIN | cut -d" " -f4- | sort | uniq -c | sort -nr;
   
##### Abuse Check section #####
##  xmlrpc attack ##
echo -e "\n$H1===========$H2 xmlrpc Attack Checker $H1===========$RS";
xmlattack=$(cat /usr/local/apache/domlogs/$THEACCOUNT/$THEDOMAIN | grep "POST /xmlrpc.php" | wc -l);
if [ $xmlattack = 0 ]; then
  echo -e "$G1 No attack detected $RS"
else
  echo -e "Account has been hit $xmlattack times.";
fi
findip=$(cat /usr/local/apache/domlogs/$THEACCOUNT/$THEDOMAIN | awk '{print $1}' | grep -v `hostname -i` | sort -nk1 | uniq -c | sort -nrk1 | head -10);
echo -e "\nThese are the IPs that hit it the most:";
echo -e "$findip";

## Used to find mail in mail queue from a user
echo -e "\n$H1===========$H2 Mail in the Queue Checker $H1===========$RS";
find /var/spool/exim/input/ -type f -name '*-H' -exec grep -Eq $THEDOMAIN '{}' \; -and -print | awk -F/ '{system("");sub(/-[DH]$/,"",$7);print $7}' | wc -l;

## ftpupload
echo -e "\n$H1===========$H2 FTP Uploads Checker $H1===========$RS";
        grep 'upload' /var/log/messages* | grep $THEDOMAIN | tail -10;

## findlarge_archives
echo -e "\n$H1===========$H2 Data Warehousing Check $H1===========$RS";
cd /home/$THEACCOUNT/; 
find . -type f -regex ".*\.\(zip\|7z\|iso\|shar\|lz\|lzma\|lzo\|rz\|ace\|cab\|dd\|dmg\|j\|cue\|bin\|uif\|rar\|bz2\|izo\|gz\|tar\|tgz\)" -exec du -h {} \; | grep -Ev "[0-9]+\.[0-9]{1}K|[0-9]+K|[0-9]+\.[0-9]{1}M|[0-9]\{2\}M|0[[:space:]]+.\/" | grep -E "[0-9]{3}M|[0-9]+\.[0-9]{1}G";

## Check last 7 days of dcpumonview for the account
echo -e "\n$H1===========$H2 The last 7 days of dcpumonview for $THEACCOUNT $H1===========$RS";

    for i in `seq 1 7 `;
    do
        let i=$i+1;
        let k=$i-1;
        let s="$(date +%s) - (k-1)*86400";
        let t="$(date +%s) - (k-2)*86400";
        echo `date -Idate -d @$s`;
        /usr/local/cpanel/bin/dcpumonview `date -d @$s +%s` `date -d @$t +%s` | sed -r -e 's@^<tr bgcolor=#[[:xdigit:]]+><td>(.*)</td><td>(.*)</td><td>(.*)</td><td>(.*)</td><td>(.*)</td></tr>$@Account: \1\tDomain: \2\tCPU: \3\tMem: \4\tMySQL: \5@' -e 's@^<tr><td>Top Process</td><td>(.*)</td><td colspan=3>(.*)</td></tr>$@\1 - \2@' | grep --color=auto "Domain: $THEDOMAIN" -A3;
    done;

echo -e "\n$H1========$H2 Done by $R1 Muhamed Hamid $H1=========$RS";
    
####### End abuser check ##########

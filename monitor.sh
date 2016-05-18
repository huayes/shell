#!/bin/bash
PKEY=`mysql -uinsconn -p'password' jiradb -h 192.168.100.230 -e 'SELECT pkey FROM jiraissue WHERE RESOLUTION IS NULL ORDER BY ID DESC LIMIT 1'|grep GD`
USERNAME='user'
PASSWORD='password'
DASHBOARD_PAGE_URL='http://ip/jira/secure/Dashboard.jspa'
MONITOR_PAGE_URL="http://ip/jira/browse/$PKEY"
COOKIE_FILE_LOCATION='/etc/zabbix/bin/jiracoookie.txt'
curl -k -s --head -u $USERNAME:$PASSWORD --cookie-jar $COOKIE_FILE_LOCATION $DASHBOARD_PAGE_URL 1>/dev/null 2>/dev/null
curl -k -s --cookie $COOKIE_FILE_LOCATION $MONITOR_PAGE_URL |grep '>更多工作流动作' 1>/dev/null 2>/dev/null
if [[ $? == 0 ]];then
	echo 1
else
	echo 0
        echo "`date`----$PKEY" >> /data/log/zabbix/jira.log
fi
rm -f $COOKIE_FILE_LOCATION

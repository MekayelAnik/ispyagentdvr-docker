#!/bin/bash
systemctl start AgentDVR.service
echo -e "Starting AgentDVR Surveillance System!\n"
echo -e "To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.2.12:8090/\n\n"
echo -e "Our software is free to use locally for private use. You can add as many cameras as you like.\nSSL secured web access, SMS, Twitter, email alerts, mobile device access, cloud uploads, Virtual Reality and other services that use iSpy Agent DVR online platform require a subscription or an annual payment.\n"
echo -e "If you desire to obtain a Subscription plan or want a Business License, please visit: https://www.ispyconnect.com/pricing.aspx"
while true
do sleep 126144000
done
exit 0
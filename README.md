gatekeeper

Run the installer script to
- import the gatekeeper.sh script for moving data
- add the File and Content tables to mysql
- configure cron job to run gatekeeper script at intervals
- configure samba share for dropoff location

This service provides

1) moving data out of shares and into the application workspace
2) verifying the contents
3) adding a content and file entry for all content added


The Content and File tables schemas are included in the lib/ directory 

- install cmkvault server (w/database)
- Ensure python-mysql is installed
- populate config.cfg file in config directory

dependencies:
python-mysql
python 2.7
cmkvault server
mysql-server







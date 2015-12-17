''' 
File: process_item.py
Date 12-15-15
last revised: 

To be used with the cromaca file server to:
- integrate new files into directory structure
- log the additions made
- add a Content and File table entry for the item

Items are processed one per run to avoid congestion.

'''

###############################################################################
# Script variables  
###############################################################################
objectPath = '/hold/'
trashPath = '/trash/'
logPath = '/logs/'
contentPath = '/content/'
rootPath = '/home/cromaca'
# TODO: decide on credential management task #10 on ss
configPath = '/config/'
extentions = ['mp4', 'flv', 'jpg', 'ebm', 'gif'] # ebm is a hack for webm

delim = "|"
timestamp = datetime.datetime.now().strftime("%Y%d%H%M%S") # '201309130134'
datestr = datetime.datetime.now().strftime("%m-%d-%Y")
method = 'PROCITEM_SCRIPT'
now = time.strftime('%Y-%m-%d %H:%M:%S')

error_trap = ""


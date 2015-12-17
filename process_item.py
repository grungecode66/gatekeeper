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


import os
import hashlib
import sys
import MySQLdb
import datetime
import string
import random


###############################################################################
# Script variables  
###############################################################################
objectPath = '/hold/'
trashPath = '/trash/'
logPath = '/logs/'
contentPath = '/content/'
rootPath = '/home/cromaca'
configPath = '/config/'
extentions = ['mp4', 'flv', 'jpg', 'ebm', 'gif'] # ebm is a hack for webm
delim = "|"
timestamp = datetime.datetime.now().strftime("%Y%d%H%M%S") # '201309130134'
datestr = datetime.datetime.now().strftime("%m-%d-%Y")
method = 'PROCITEM_SCRIPT'
now = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')

###############################################################################
# Setup a database connection with credentials provided
###############################################################################
dbInfo = open(rootPath + configPath + 'dbinfo.txt').read().splitlines()
db = MySQLdb.connect(host=dbInfo[0], # your host, usually localhost
        user=dbInfo[1], # your username
        passwd=dbInfo[2], # your password
        db=dbInfo[3]) # name of the data base   

cur = db.cursor()

###############################################################################
# return the md5 of the file passed to it        
###############################################################################
def HashCalc(fname):
        try:
                f = file(rootPath + objectPath + fname,'rb')
                Data =f.read()
                MD5 = hashlib.md5(Data).hexdigest()
        except:
                errFile.write('MD5 error: Failed To Open File ' + (rootPath + objectPath + fname))
                errFile.close()
                sys.exit()
        f.close()
        return MD5


###############################################################################
# return a string of 'size' alphanumeric chars
###############################################################################
def get_random_ai(size = 4, chars=string.ascii_uppercase + string.digits):
        return ''.join(random.choice(chars) for x in range(size))



###############################################################################
# Rename the file string
###############################################################################
def safe_rename(old_name):
	return get_random_ai(4) + "_" + old_name 



###############################################################################
# return folder path string based on extension
###############################################################################
def getcontentpath(ftype, endc = '/'):
        if ftype == "jpg":
                return (rootPath + contentPath + "image" + endc)
        elif ftype == "mp4":
                return (rootPath + contentPath + "video" + endc)
        elif ftype == "gif":
                return (rootPath + contentPath + "gif" + endc)
        elif ftype == "ebm":
                return (rootPath + contentPath + "gif" + endc)
        else:
                errFile.write("FATAL ERROR: File extension '" + ftype + "' not found for item " + new_item + "\n")
                sys.exit(1)

###############################################################################
# open error log
###############################################################################
errFileName = logPath + 'error_' + timestamp + '.log'
errFile = open((rootPath + errFileName), 'w')

###############################################################################
# collect all of the stored hashes for comparison
###############################################################################
try:
        cur.execute("SELECT * FROM Content")
except:
        errFile.write("Could not obtain MD5 list from database while processing " + new_item + "\n")
        sys.exit(1)
md5InDb = []

# get a list of hashes currently in the database
for row in cur.fetchall():
   md5InDb.append(row[1])


###############################################################################
# process the item
###############################################################################
filehash = HashCalc(new_item)
if filehash in md5InDb: # already in database COLLISION
        os.rename((rootPath + objectPath + new_item), (rootPath + trashPath + new_item))  # move the dupe
        errFile.write("Duplicate file detected: " + new_item + ". Moved to trash.\n")
else:

        filesql  = """INSERT INTO File (file_name, file_sid, file_abs_path, file_date_added, file_source) VALUES (%s, %s, %s, %s, %s)"""

        contentsql = """INSERT INTO Content (content_sid, content_file, content_activity_date, content_type) VALUES (%s%s%s%s)"""

        try:
                if not os.path.exists((getcontentpath(extn) + new_item)):
			os.rename((rootPath + objectPath + new_item), (getcontentpath(extn) + new_item))
		else:
			old_name = new_item
			new_item = safe_rename(new_item)			
			os.rename((rootPath + objectPath + old_name), (getcontentpath(extn) + new_item))
                cur.execute(filesql , (new_item, filehash, getcontentpath(extn) , now, method ))
                cur.execute(contentsql, filehash, new_item, now, extn)
                db.commit()
        except:
                errFile.write(filesql + "\n\n" + contentsql + "\n\n" + new_item + " Database or duplicate error: not added to db.")


###############################################################################
# write to log that the content was added
###############################################################################
try:
        # content.log will contain a line such as
        # 2015-10-22|abcdef1234567890abcdef1234567890|somefile.ext
        # this will be the report referenced in task item #2
        contentlog = open((rootPath + logPath + 'content.log') , 'a')
        contentlog.write(datestr + delim + filehash + delim + new_item + "\n")
except:
        errFile.write("Error writing to content.log for item: " + new_item + " hash: " + filehash + "\n")
finally:
        contentlog.close()

errFile.close()




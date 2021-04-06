# этот скрипт скачивает эти страницы по одному
import requests
from courseraoauth2client import oauth2
import json
import wget
from tqdm import tqdm
import os, sys

course_slug = "politika-sravnitelnaja"
where_to_download = "/home/vovan/Desktop/down/" + course_slug + "/"
print where_to_download
course = "jC3H-47qEeWxTA6NLywNHw"
startDate = "2016-11-10"
endDate = "2016-12-10"
url = 'https://www.coursera.org/api/clickstreamExportsDownload.v1?action=generateLinks&scope=courseContext~' + course +'&startDate=' + startDate + '&endDate=' + endDate


auth = oauth2.build_oauth2(app='manage_research_exports').build_authorizer()
response = requests.post(url, auth=auth)

#soxraniaetsia ssilki na faili
with open("/home/vovan/Desktop/data.json", 'w') as fp:
    json.dump(response.json(), fp)

#skachivaiutsia faili
for url in tqdm(response.json()):
    #print url
    try:
        filename = url.split("/")[8].split("?")[0]
        print filename
        if filename not in os.listdir(where_to_download):
            wget.download(url, where_to_download)
            #print filename
    except (KeyboardInterrupt, SystemExit):
        raise
    except:
        continue
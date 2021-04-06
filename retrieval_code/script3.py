# this script sens a request to coursera, downloads files and write the download conditions into names.csv
import requests
from courseraoauth2client import oauth2
import json
import wget
import os
import datetime
import schedule, time
import pandas as pd
import sys
import re
from datetime import datetime

# https://docs.google.com/spreadsheets/d/1MxyuWyVzvThzZ8fKxDY_LhTu5ifCxiNcIe6vmq055PA/edit#gid=2109450249
#### 1
cwd = os.getcwd()
endDate = "2020-09-16"

def max_day(where_to_download):
    a = os.listdir(where_to_download)
    aa = filter(lambda x:'access' in x, a)
    aaa = []
    for item in aa:
        aaa.append(re.findall('access-([^ ]*).csv.gz', item))
    flat_list = []
    for sublist in aaa:
        for item in sublist:
            flat_list.append(item)
    maxx = max(flat_list, key=lambda d: datetime.strptime(d, '%Y-%m-%d'))
    print maxx
    return maxx

def authen():
    try:
        auth = oauth2.build_oauth2(app='manage_research_exports').build_authorizer()
    except:
        auth = ""
    return auth


def authen2():
    auth = ""
    i = 0
    while auth == "":
        auth = authen()
        if auth == "":
            i += 1
            print "try", str(i) + ",", "retry in two minutes"
            time.sleep(120)
    return auth

def call_coursera(j, flag):
    df = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
    while df["ready"][j] != "0":
        j += 1
    course = df["course_id"][j]
    course_slug = df["course_slug"][j]
    where_to_download = "/home/vovan/Desktop/down/" + course_slug + "/"
    #startDate = df["course_launch_ts"][j].split(" ")[0]
    if (flag == 0):
        startDate = max_day(where_to_download)
        endDate = "2020-09-16"
    else:
        startDate = df["course_launch_ts"][j].split(" ")[0]
        endDate = max_day(where_to_download)
    REQUEST_JSON = {"scope": {"typeName": "courseContext", "definition": {"courseId": course}},
        "exportType": "RESEARCH_EVENTING", "schemaNames": ["course_grades"],
        "anonymityLevel": "HASHED_IDS_NO_PII", "statementOfPurpose": "Test",
        "interval": {"start": startDate, "end": endDate}}
    print REQUEST_JSON
    url = "https://www.coursera.org/api/onDemandExports.v2"
    auth = authen2()
    resp = requests.post(url, auth=auth, json=REQUEST_JSON)
    print resp.json()
    return j, course, startDate, course_slug


#### 2
def down_coursera(course, startDate, endDate, course_slug):
    url = 'https://www.coursera.org/api/clickstreamExportsDownload.v1?action=generateLinks&scope=courseContext~' + course +'&startDate=' + startDate + '&endDate=' + endDate
    time = datetime.strptime(endDate, "%Y-%m-%d") - datetime.strptime(startDate, "%Y-%m-%d")
    links = int(time.days) * 2
    #print url
    #print "links ", links
    where_to_download = "/home/vovan/Desktop/down/" + course_slug + "/"
    if not os.path.exists(where_to_download):
        os.mkdir(where_to_download)
    auth = authen2()
    response = requests.post(url, auth=auth)
    actual = len(response.json())
    print course_slug, "ready to download", str(actual) + ":", "downloading"
    i = 0
    # soxraniaetsia ssilki na faili
    with open("/home/vovan/Desktop/data.json", 'w') as fp:
        json.dump(response.json(), fp)
        # skachivaiutsia faili
    for url in response.json():
        try:
            filename = url.split("/")[8].split("?")[0]
            if filename not in os.listdir(where_to_download):
                wget.download(url, where_to_download)
                i = i + 1;
                print str(i),
                sys.stdout.flush()
        except (KeyboardInterrupt, SystemExit):
            raise
        except:
            continue
    print "downloaded this iteration: ", i
    return actual, where_to_download

#### 3

j = 1

def isend(cwd):
    df = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
    count = 0
    for i in range(40):
        if df["ready"][i] != "0":
            count += 1
    return count

count = 0
while count <= 112:
    count = 0
    flag = 0
    while j <= 112:
        j, course, startDate, course_slug = call_coursera(j, flag)
        ac0 = 0
        ac1 = -1
        b = 1
        while ac1 != ac0:
            ac1, where_to_download = down_coursera(course, startDate, endDate, course_slug)
            already_down = len(os.listdir(where_to_download))
            if ac1 != -1:
                ac0 = ac1
            print course_slug, '-', 'links ', ac1, ' files', already_down, datetime.now().time()
            if ac0 != ac1 & ac1 != -1:
                print "wait 5 sec"
                time.sleep(5)
            else:
                print "wait 60 seconds"
                time.sleep(60)
                if b == 1:
                    b = 0
                    ac1 -= 1
        df = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
        if os.path.exists(where_to_download + "video-2020-09-16.csv.gz") == True & os.path.exists(where_to_download + "access-2020-09-16.csv.gz") == True:
            df['ready'].iloc[j] = 'done'
        df.to_csv(''.join([cwd, '/names.csv']), index=False)
        print "ready for new course", cwd, j
        j += 1
    for i in range(1, 112):
        if df["ready"][i] != "0":
            count += 1
            print count, 'courses are ready'
    #flag = 0


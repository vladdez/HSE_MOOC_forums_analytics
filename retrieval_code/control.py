# this script writes in problems.csv courses that were not fully downloades and how many left to download
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

endDate = "2020-09-16"
cwd = os.getcwd()
df = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
i = 0
tab = []
probl = pd.read_csv(''.join([cwd, '/problems.csv']), sep=',')
tab.append(["index", "course_id", "course_slug", "course_launch_ts", "access_n", "video_n", "actual_days", "delta", "update"])
for j in range(99):
    course = df["course_id"][j]
    course_slug = df["course_slug"][j]
    where_to_download = "/home/vovan/Desktop/down/" + course_slug + "/"
    a = os.listdir(where_to_download)
    a1 = filter(lambda x:'access' in x, a)
    a2= filter(lambda x: 'video' in x, a)
    startDate = df["course_launch_ts"][j].split(" ")[0]
    time = datetime.strptime(endDate, "%Y-%m-%d") - datetime.strptime(startDate, "%Y-%m-%d")
    time = int(time.days)
    startDate = df["course_launch_ts"][j].split(" ")[0]
    #print course_slug, len(a1), len(a2), time
    if len(a1) < (time - 1):
        i += 1
        delta = time - len(a1)
        if (probl[probl["course_id"] == course]["delta"]).values[0] != delta:
            update = "u"
        else:
            update = "not"
        tab.append([i, course, course_slug, startDate, len(a1), len(a2), time, delta, update])

print tab

import csv

with open("problems.csv", "wb") as f:
    writer = csv.writer(f)
    writer.writerows(tab)



# this script renames folders in september2020, to make them similar with course_slug
from __future__ import print_function
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


cwd = os.getcwd()
names = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
dir_path = "/home/vovan/Desktop/september_2020"
dirs = os.listdir(dir_path)
#dirs = list(filter(lambda x: "_" in x, dirs))
print (dirs)
df = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')

j = 0
for i in range(len(dirs)):
    tmp = dir_path + "/" + dirs[i] + "/" + "courses.csv"
    c = pd.read_csv(tmp)
    cc = dir_path + "/" + c["course_slug"][0]
    dd = dir_path + "/" + dirs[i]
    if dirs[i] not in list(df["course_slug"]):
        tmp = pd.read_csv(''.join([dir_path,'/', dirs[i], '/courses.csv']), sep=',')
        print (tmp["course_id"][0], dirs[i], tmp["course_launch_ts"][0], "0", sep=', ')



    #os.rename(dd, cc)

# coding=utf-8
# этот скрипт поправляет столбец ready в names.csv если она сбилась. Поправка производииться на основе problems.csv
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

problem = pd.read_csv(''.join([cwd, '/problems.csv']), sep=',')
names = pd.read_csv(''.join([cwd, '/names.csv']), sep=',')
def find(row, name):
    for i in range(len(row)):
        if row[i] == name:
            return 1
    return 0

s = pd.Series(problem["course_slug"])
'''
for i in range(99):
    if find(s, names["course_slug"][i]) == 1:
        names["ready"][i] = "0"
    else:
        names["ready"][i] = "done"
    names.to_csv(''.join([cwd, '/names.csv']), index=False)
'''
#print (min(names["course_launch_ts"]))

a = sorted(names["course_slug"])
for i in range(114):
    print (a[i])
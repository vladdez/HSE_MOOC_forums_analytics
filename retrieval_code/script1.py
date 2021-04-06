# этот скрипт отправляет запрос на формирование ссылок курсерой
import requests
from courseraoauth2client import oauth2

REQUEST_JSON = {"scope": {"typeName": "courseContext", "definition": {"courseId": "jC3H-47qEeWxTA6NLywNHw"}},
                "exportType": "RESEARCH_EVENTING", "schemaNames": ["course_grades"],
                "anonymityLevel": "HASHED_IDS_NO_PII", "statementOfPurpose": "Test",
                "interval": {"start": "2016-11-10", "end": "2016-12-10"}}

url = "https://www.coursera.org/api/onDemandExports.v2"
auth = oauth2.build_oauth2(app='manage_research_exports').build_authorizer()
resp = requests.post(url, auth=auth, json=REQUEST_JSON)
print resp.json()

import os
import urllib.parse
from cookies import Cookie, Cookies
from requests_oauthlib import OAuth2Session
from requests.auth import HTTPBasicAuth
    
CLIENT_ID = os.environ['OAUTH_CLIENT_ID']
CLIENT_SECRET = os.environ['OAUTH_CLIENT_SECRET']
TOKEN_URL = os.environ['OAUTH_TOKEN_URL']
HOME_URL = os.environ['OAUTH_HOME_URL']
REDIRECT_URI = os.environ['OAUTH_REDIRECT_URI'] # my callback
AUTH = HTTPBasicAuth(CLIENT_ID, CLIENT_SECRET)


def get_uri(event):
    host = event['headers']['Host']
    stage = event['requestContext']['stage']
    path = event['path']
    query = "&".join([f"{key}={urllib.parse.quote_plus(val)}" for key, val in event['queryStringParameters'].items()])
    return f"https://{host}/{stage}{path}?{query}"


def handler(event, context):
    cookie_header = event["headers"]["Cookie"]
    cookies = Cookies.from_request(cookie_header)
    oauth_session = OAuth2Session(CLIENT_ID, state=cookies['oauth_state'].value, redirect_uri=REDIRECT_URI)
    oauth_token = oauth_session.fetch_token(
        TOKEN_URL,
        client_secret=CLIENT_SECRET,
        auth=AUTH,
        include_client_id=True,
        authorization_response=get_uri(event)
    )

    cookie_session = Cookie("oauth_token", oauth_token['id_token'], secure=True, httponly=True)
    return {
        "statusCode": 302,
        "headers": {
            "location": HOME_URL,
            "set-cookie": cookie_session.render_response()
        }
    }

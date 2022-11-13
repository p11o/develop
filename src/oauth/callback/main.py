import os

from cookies import Cookie, Cookies
from requests_oauthlib import OAuth2Session


CLIENT_ID = os.environ['OAUTH_CLIENT_ID']
CLIENT_SECRET = os.environ['OAUTH_CLIENT_SECRET']
TOKEN_URL = os.environ['OAUTH_TOKEN_URL']
HOME_URL = os.environ['OAUTH_HOME_URL']


def handler(event, context):
    cookie_header = event["headers"]["Cookie"]
    cookies = Cookies.from_request(cookie_header)

    oauth_session = OAuth2Session(CLIENT_ID, state=cookies['oauth_state'])
    oauth_token = oauth_session.fetch_token(TOKEN_URL, client_secret=CLIENT_SECRET)

    cookie_session = Cookie("oauth_token", oauth_token, secure=True, httponly=True)
    return {
        "statusCode": 302,
        "headers": {
            "location": HOME_URL,
            "set-cookie": cookie_session.render_response()
        }
    }

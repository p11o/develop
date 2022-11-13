import os

from cookies import Cookie
from requests_oauthlib import OAuth2Session


CLIENT_ID = os.environ['OAUTH_CLIENT_ID']
SCOPE = os.getenv('OAUTH_SCOPE', 'email,profile,openid').split(',')
REDIRECT_URI = os.environ['OAUTH_REDIRECT_URI'] # my callback
AUTHORIZATION_BASE_URL = os.environ['OAUTH_AUTHORIZATION_BASE_URL']
COOKIE_SESSION_MAX_AGE = 60 * 10 # ten minutes


def handler(event, context):
    oauth_session = OAuth2Session(CLIENT_ID, redirect_uri=REDIRECT_URI, scope=SCOPE)
    authorization_url, state = oauth_session.authorization_url(AUTHORIZATION_BASE_URL)
    
    cookie_session = Cookie("oauth_state", state, max_age=COOKIE_SESSION_MAX_AGE, secure=True, httponly=True)
    return {
        "statusCode": 302,
        "headers": {
            "location": authorization_url,
            "set-cookie": cookie_session.render_response()
        }
    }


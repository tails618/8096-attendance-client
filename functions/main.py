# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

# The Cloud Functions for Firebase SDK to create Cloud Functions and set up triggers.
import time
from firebase_functions import scheduler_fn, db_fn, https_fn, options

# The Firebase Admin SDK to access the Firebase Realtime Database.
from firebase_admin import initialize_app, db

from typing import Any
import datetime

app = initialize_app()


# @https_fn.on_request()
# def on_request_example(req: https_fn.Request) -> https_fn.Response:
#     return https_fn.Response("Hello world!")

@scheduler_fn.on_schedule(schedule="30 23 * * *", timezone=scheduler_fn.Timezone("America/Chicago"),)
def nightSignOut(event: scheduler_fn.ScheduledEvent) -> None:
    root = db.reference('/').get()
    for uid in root:
        state = db.reference(f"/{uid}/state").get()
        if state == "in":
            check_out(uid)

# @db_fn.on_value_created(reference="/test")
# def nightSignOut(event: db_fn.Event) -> None:
#     root = db.reference('/').get()
#     for uid in root:
#         if uid != "test":
#             db.reference(f"/{uid}").update({"state": "out"})

@https_fn.on_call()
def manualSignOut(req: https_fn.CallableRequest) -> Any:
    check_out(req.auth.uid)

@https_fn.on_call()
def uidSignOut(req: https_fn.CallableRequest) -> Any:
    check_out(req.data['uid'])

def check_out(user_id):
    counter = db.reference(f'{user_id}/counter').get()

    latest_time_out = int(datetime.datetime.now().timestamp() * 1000)
    latest_time_in = db.reference(f'{user_id}/sessions/{counter}/timeIn').get()


    total_time_milliseconds = db.reference(f'{user_id}/totalTime').get()

    total_sessions = db.reference(f'{user_id}/totalSessions').get()

    set_user_val(f'{user_id}/sessions/{counter}/timeOut', latest_time_out)

    duration = latest_time_out - latest_time_in
    new_total_time = total_time_milliseconds + duration

    new_sessions = 0

    if duration >= (6*60*60*1000 + 30*60*1000): # 6 hours 30 minutes
        new_sessions = 2
    elif duration >= (2*60*60*1000 + 30*60*1000): # 2 hours 30 minutes
        new_sessions = 1

    set_user_val(f'{user_id}/sessions/{counter}/sessions', new_sessions)

    set_user_val(f'{user_id}/totalSessions', total_sessions + new_sessions)

    set_user_val(f'{user_id}/totalTime', new_total_time)
    set_user_val(f'{user_id}/counter', counter + 1)
    set_user_val(f'{user_id}/state', 'out')

def set_user_val(path, value):
    ref = db.reference(path)
    ref.set(value)
# # # The Cloud Functions for Firebase SDK to set up triggers and logging.
# from firebase_functions import scheduler_fn, db_fn, https_fn

# # The Firebase Admin SDK to delete users.
# import firebase_admin
# from firebase_admin import auth, initialize_app, db

# firebase_admin.initialize_app()

# # Run once a day at midnight, to clean up inactive users.
# # Manually run the task here https://console.cloud.google.com/cloudscheduler
# @scheduler_fn.on_schedule(schedule="59 11 * * *", timezone=scheduler_fn.Timezone("America/Chicago"),)

# # # Check out all users at 11:59pm daily
# # def nightSignOut(event: scheduler_fn.ScheduledEvent) -> None:
# #     reference = r"/{uid}"
# #     db.reference(reference).update({"state": "out"})




# # # def accountcleanup(event: scheduler_fn.ScheduledEvent) -> None:
# # #     """Delete users who've been inactive for 30 days or more."""
# # #     user_page: auth.ListUsersPage | None = auth.list_users()
# # #     while user_page is not None:
# # #         inactive_uids = [
# # #             user.uid for user in user_page.users if is_inactive(user, timedelta(days=30))
# # #         ]
# # #         auth.delete_users(inactive_uids)
# # #         user_page = user_page.get_next_page()
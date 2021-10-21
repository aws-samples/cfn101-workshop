from datetime import datetime

from pytz import timezone, utc


def handler(event, context):
    payload = event["time_zone"]
    message = "Current date/time in TimeZone *{}* is: {}".format(
        payload, _timezone(payload)
    )

    return {"message": message}


def _timezone(time_zone):
    utc_now = utc.localize(datetime.utcnow())
    compare_to_utc = utc_now.astimezone(timezone(time_zone))

    return compare_to_utc.strftime("%Y-%m-%d %H:%M")

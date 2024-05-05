import requests


def handler(event, context):
    print(event)
    print(context)
    return 'Hello AWS again Lambda'

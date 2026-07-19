#!/usr/bin/env python3
import sys
import json
import threading
import time
import html as html_mod

class Notification:
    def __init__(self, summary, body, icon, source):
        self.summary = summary or ''
        self.body = body or ''
        self.icon = icon or ''
        self.source = source or ''

notifications = []
lock = threading.RLock()

def remove_notification(notif):
    time.sleep(10)
    with lock:
        if notif in notifications:
            notifications.remove(notif)
        print_state()

def add_notification(notif):
    with lock:
        notifications.insert(0, notif)
        print_state()
    timer_thread = threading.Thread(target=remove_notification, args=(notif,), daemon=True)
    timer_thread.start()

def escape_text(text):
    return html_mod.escape(str(text), quote=True)

def print_state():
    with lock:
        string = ""
        for item in notifications:
            string += f"""
                      (button :class 'notif'
                       (box :orientation 'horizontal' :space-evenly false
                          (image :image-width 80 :image-height 80 :path '{escape_text(item.icon)}')
                          (box :orientation 'vertical'
                            (label :width 200 :wrap true :text '{escape_text(item.summary)}')
                            (label :width 200 :wrap true :text '{escape_text(item.body)}')
                      )))
                      """
        string = string.replace('\n', ' ')
        print(fr'''(box :orientation 'vertical' {string or ''})''', flush=True)

if __name__ == '__main__':
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            data = json.loads(line)
            summary = data.get('summary', '')
            body = data.get('body', '')
            icon = data.get('icon', '')
            source = data.get('source', '')
            add_notification(Notification(summary, body, icon, source))
        except json.JSONDecodeError:
            continue

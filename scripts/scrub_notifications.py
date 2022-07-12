#!/usr/bin/env python3
"""
Runs a DBus message loop with a callback to receive... pretty much
anything on a session bus.
Listen to the Notify event; if it's a message we hate, record it, then
listen for the return message, and kill that message.

Tested On:
- Ubuntu 18.04.5 LTS, CPython 3.6.9 (dbus: 1.2.6, gi: 3.26.1)

To test, try running the following with and without this script running:

    notify-send \
        --icon=/usr/share/pixmaps/debian-logo.png --urgency=critical \
        "Fake: Mouse battery low" "Some text body"

Notes:
- This is hella inefficient. It was hard to get filtering via this interface to
work properly... Perhaps GNOME has something better in a JavaScript API?
- DBus said "eavesdrop" is bad:
  - BecomeMonitor should be used instead.
  - Mutating stuff (man in the middle) is bad...
  - but meh. This works for now?

Based on:

- https://askubuntu.com/questions/89279/listening-to-incoming-libnotify-notifications-using-dbus/190759#190759
- https://askubuntu.com/questions/985963/disable-mouse-battery-low-spam-notification

References:

- https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus
- https://dbus.freedesktop.org/doc/dbus-python/tutorial.html
- https://developer.gnome.org/notification-spec/

"""

from collections import namedtuple

from gi.repository import GLib
import dbus
from dbus.mainloop.glib import DBusGMainLoop

# Similary to `dnotify` package.
BUS = "org.freedesktop.Notifications"
OBJECT = "/org/freedesktop/Notifications"
IFACE = "org.freedesktop.Notifications"

# For the "Notify" event (see references above).
KEYS = (
    "app_name",
    "replaces_id",
    "app_icon",
    "summary",
    "body",
    "actions",
    "hints",
    "expire_timeout",
)

CallKey = namedtuple("CallKey", ("sender", "dest", "serial"))


def i_hate_this_message(summary, body):
    if "Mouse battery low" in summary:
        return True
    return False


def main():
    call_keys_to_filter = set()  # Set[CallKey]

    def on_call(message):
        kwargs = dict(zip(KEYS, message.get_args_list()))
        summary = str(kwargs["summary"])
        body = str(kwargs["body"])
        if i_hate_this_message(summary, body):
            key = CallKey(
                sender=message.get_sender(),
                dest=message.get_destination(),
                serial=message.get_serial(),
            )
            assert key not in call_keys_to_filter
            call_keys_to_filter.add(key)

    def on_possible_return(message):
        # Use caller's key.
        caller_key = CallKey(
            sender=message.get_destination(),
            dest=message.get_sender(),
            serial=message.get_reply_serial(),
        )
        if caller_key not in call_keys_to_filter:
            return
        call_keys_to_filter.remove(caller_key)
        id_, = message.get_args_list()
        print(f"Closing: {id_}")
        iface.CloseNotification(id_)

    def on_any(bus, message):
        if (message.get_interface() == IFACE
            and message.get_member() == "Notify"):
            on_call(message)
        elif isinstance(message, dbus.lowlevel.MethodReturnMessage):
            # Yuck! But dunno how to sniff otherwise.
            on_possible_return(message)

    dbus_loop = DBusGMainLoop()
    bus = dbus.SessionBus(mainloop=dbus_loop)
    bus.add_match_string_non_blocking(f"eavesdrop=true")
    bus.add_message_filter(on_any)
    proxy = bus.get_object(bus_name=BUS, object_path=OBJECT)
    iface = dbus.Interface(proxy, dbus_interface=IFACE)

    main_loop = GLib.MainLoop()
    main_loop.run()


if __name__ == "__main__":
    main()

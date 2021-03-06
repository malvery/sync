#!/usr/bin/python3
import setproctitle
import subprocess
import signal
import i3ipc
import os

PROCESS_NAME = "i3ipc-recent-window"
PID_CURR = os.getpid()
PID_PATH = '%s/%s.pid' % (os.getenv("XDG_RUNTIME_DIR", '/tmp'), PROCESS_NAME)

################################################################################

# send SIGNTERM for another processes
pid_list = subprocess.check_output([
    '/bin/bash', '-c', 'pidof %s || true' % PROCESS_NAME
]).decode('utf-8')
pid_list = pid_list.replace('\n', '').split(' ')

for pid in pid_list:
    if pid:
        subprocess.call(['kill', pid])

with open(PID_PATH, 'w') as pid_file:
    pid_file.write(str(PID_CURR))


################################################################################


class RecentClients(object):
    curr = None  # last current window
    prev = None  # previous window

    def __init__(self, workspace):
        # save workspace index
        self.workspace = workspace


setproctitle.setproctitle(PROCESS_NAME)
switcher_containers = dict()


################################################################################


def get_switcher_item(i3):
    w_tree = i3.get_tree()
    focused = w_tree.find_focused()
    workspace_n = focused.workspace().num

    s_container = switcher_containers.get(workspace_n)
    if s_container.curr is None:
        s_container.curr = focused.id

    return s_container, focused, w_tree


def switch_to_recent(i3):
    s_container, focused, w_tree = get_switcher_item(i3=i3)

    if s_container.prev is not None:
        result = i3.command('[con_id="%s"] focus' % s_container.prev)
        if isinstance(result, list) and result:
            if isinstance(result[0], i3ipc.CommandReply) and getattr(result[0], 'success') is True:
                return True

    # empty history
    i3.command('focus right')


################################################################################

i3_conn_commands = i3ipc.Connection()


# noinspection PyPep8Naming
def on_signal(signalNumber, frame):
    if signalNumber == 10:
        switch_to_recent(i3=i3_conn_commands)

    elif signalNumber == 2:
        os.remove(PID_PATH)
        exit()


signal.signal(signal.SIGUSR1, on_signal)
signal.signal(signal.SIGINT, on_signal)


################################################################################


def on_window_focus(i3, e):
    s_container, focused, w_tree = get_switcher_item(i3=i3)
    window_id = focused.id

    # check prev window workspace
    if s_container.prev:
        w_prev = w_tree.find_by_id(s_container.prev)
        if w_prev is not None and w_prev.workspace().num != s_container.workspace:
            # reset prev client
            s_container.prev = None

    # swap last_curr and recent
    if s_container.curr != window_id:
        s_container.prev = s_container.curr
        s_container.curr = window_id


# init switcher containers
for i in range(1, 10):
    switcher_containers[i] = RecentClients(workspace=i)

i3_conn_events = i3ipc.Connection()
i3_conn_events.on(i3ipc.Event.WINDOW_FOCUS, on_window_focus)
i3_conn_events.main()

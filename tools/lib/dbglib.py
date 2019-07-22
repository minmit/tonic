import sys, inspect

LOG_LEVEL_ERROR     = 0
LOG_LEVEL_WARNING   = 1
LOG_LEVEL_ALL       = 2

LOG_LEVEL = LOG_LEVEL_ALL
DEBUG = True
DEFAULT_LOG_STREAM = sys.stdout

class clr:
    RED     = '\033[91m'
    GREEN   = '\033[92m'
    YELLOW  = '\033[93m'
    BLUE    = '\033[94m'
    CYAN    = '\033[96m'
    RST_CLR = '\033[0m'

def getFuncLine():
    # stack: [0] - current, [1] - print_* function, [2] - program
    frame_record = inspect.stack()[2]
    frame = frame_record[0]
    info = inspect.getframeinfo(frame)
    fname_short = info.filename.split('/')[-1]
    retval = "%s:%3d" % (fname_short, info.lineno)
    return retval

def print_debug(msg, fstream=DEFAULT_LOG_STREAM):
    if DEBUG:
        msg_print = clr.CYAN + "[DEBUG] " + getFuncLine() + clr.RST_CLR + ": " + msg.strip()
        print >> fstream, msg_print

def print_info(msg, fstream=DEFAULT_LOG_STREAM):
    if LOG_LEVEL >= LOG_LEVEL_ALL:
        msg_print = clr.BLUE + "[INFO]  " + getFuncLine() + clr.RST_CLR + ": " + msg.strip()
        print >> fstream, msg_print

def print_warning(msg, fstream=DEFAULT_LOG_STREAM):
    if LOG_LEVEL >= LOG_LEVEL_WARNING:
        msg_print = clr.YELLOW + "[WARN]  " + getFuncLine() + clr.RST_CLR + ": " + msg.strip()
        print >> fstream, msg_print

def print_error(msg, fstream=DEFAULT_LOG_STREAM):
    if LOG_LEVEL >= LOG_LEVEL_ERROR:
        msg_print = clr.RED + "[ERROR] " + getFuncLine() + clr.RST_CLR + ": " + msg.strip()
        print >> fstream, msg_print

def print_success(msg, fstream=DEFAULT_LOG_STREAM):
    if LOG_LEVEL >= LOG_LEVEL_ALL:
        msg_print = clr.GREEN + "[PASS]  " + getFuncLine() + clr.RST_CLR + ": " + msg.strip()
        print >> fstream, msg_print

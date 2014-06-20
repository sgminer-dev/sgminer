#ifndef API_H
#define API_H

#include "config.h"

#include "miner.h"

// BUFSIZ varies on Windows and Linux
#define TMPBUFSIZ 8192

// Number of requests to queue - normally would be small
#define QUEUE 100

#ifdef WIN32
struct WSAERRORS {
  int id;
  char *code;
} WSAErrors[] = {
  { 0,      "No error" },
  { WSAEINTR,   "Interrupted system call" },
  { WSAEBADF,   "Bad file number" },
  { WSAEACCES,    "Permission denied" },
  { WSAEFAULT,    "Bad address" },
  { WSAEINVAL,    "Invalid argument" },
  { WSAEMFILE,    "Too many open sockets" },
  { WSAEWOULDBLOCK, "Operation would block" },
  { WSAEINPROGRESS, "Operation now in progress" },
  { WSAEALREADY,    "Operation already in progress" },
  { WSAENOTSOCK,    "Socket operation on non-socket" },
  { WSAEDESTADDRREQ,  "Destination address required" },
  { WSAEMSGSIZE,    "Message too long" },
  { WSAEPROTOTYPE,  "Protocol wrong type for socket" },
  { WSAENOPROTOOPT, "Bad protocol option" },
  { WSAEPROTONOSUPPORT, "Protocol not supported" },
  { WSAESOCKTNOSUPPORT, "Socket type not supported" },
  { WSAEOPNOTSUPP,  "Operation not supported on socket" },
  { WSAEPFNOSUPPORT,  "Protocol family not supported" },
  { WSAEAFNOSUPPORT,  "Address family not supported" },
  { WSAEADDRINUSE,  "Address already in use" },
  { WSAEADDRNOTAVAIL, "Can't assign requested address" },
  { WSAENETDOWN,    "Network is down" },
  { WSAENETUNREACH, "Network is unreachable" },
  { WSAENETRESET,   "Net connection reset" },
  { WSAECONNABORTED,  "Software caused connection abort" },
  { WSAECONNRESET,  "Connection reset by peer" },
  { WSAENOBUFS,   "No buffer space available" },
  { WSAEISCONN,   "Socket is already connected" },
  { WSAENOTCONN,    "Socket is not connected" },
  { WSAESHUTDOWN,   "Can't send after socket shutdown" },
  { WSAETOOMANYREFS,  "Too many references, can't splice" },
  { WSAETIMEDOUT,   "Connection timed out" },
  { WSAECONNREFUSED,  "Connection refused" },
  { WSAELOOP,   "Too many levels of symbolic links" },
  { WSAENAMETOOLONG,  "File name too long" },
  { WSAEHOSTDOWN,   "Host is down" },
  { WSAEHOSTUNREACH,  "No route to host" },
  { WSAENOTEMPTY,   "Directory not empty" },
  { WSAEPROCLIM,    "Too many processes" },
  { WSAEUSERS,    "Too many users" },
  { WSAEDQUOT,    "Disc quota exceeded" },
  { WSAESTALE,    "Stale NFS file handle" },
  { WSAEREMOTE,   "Too many levels of remote in path" },
  { WSASYSNOTREADY, "Network system is unavailable" },
  { WSAVERNOTSUPPORTED, "Winsock version out of range" },
  { WSANOTINITIALISED,  "WSAStartup not yet called" },
  { WSAEDISCON,   "Graceful shutdown in progress" },
  { WSAHOST_NOT_FOUND,  "Host not found" },
  { WSANO_DATA,   "No host data of that type was found" },
  { -1,     "Unknown error code" }
};
#endif

#define COMSTR ","
#define SEPSTR "|"

#define CMDJOIN '+'
#define JOIN_CMD "CMD="
#define BETWEEN_JOIN SEPSTR
#define _DYNAMIC "D"

#define _DEVS   "DEVS"
#define _POOLS    "POOLS"
#define _SUMMARY  "SUMMARY"
#define _STATUS   "STATUS"
#define _VERSION  "VERSION"
#define _MINECONFIG "CONFIG"
#define _GPU    "GPU"

#define _GPUS   "GPUS"
#define _NOTIFY   "NOTIFY"
#define _DEVDETAILS "DEVDETAILS"
#define _BYE    "BYE"
#define _RESTART  "RESTART"
#define _MINESTATS  "STATS"
#define _CHECK    "CHECK"
#define _MINECOIN "COIN"
#define _DEBUGSET "DEBUG"
#define _SETCONFIG  "SETCONFIG"

#define JSON0   "{"
#define JSON1   "\""
#define JSON2   "\":["
#define JSON3   "]"
#define JSON4   ",\"id\":1"
// If anyone cares, id=0 for truncated output
#define JSON4_TRUNCATED ",\"id\":0"
#define JSON5   "}"

#define JSON_START  JSON0
#define JSON_DEVS JSON1 _DEVS JSON2
#define JSON_POOLS  JSON1 _POOLS JSON2
#define JSON_SUMMARY  JSON1 _SUMMARY JSON2
#define JSON_STATUS JSON1 _STATUS JSON2
#define JSON_VERSION  JSON1 _VERSION JSON2
#define JSON_MINECONFIG JSON1 _MINECONFIG JSON2
#define JSON_GPU  JSON1 _GPU JSON2

#define JSON_GPUS JSON1 _GPUS JSON2
#define JSON_NOTIFY JSON1 _NOTIFY JSON2
#define JSON_DEVDETAILS JSON1 _DEVDETAILS JSON2
#define JSON_CLOSE  JSON3
#define JSON_MINESTATS  JSON1 _MINESTATS JSON2
#define JSON_CHECK  JSON1 _CHECK JSON2
#define JSON_MINECOIN JSON1 _MINECOIN JSON2
#define JSON_DEBUGSET JSON1 _DEBUGSET JSON2
#define JSON_SETCONFIG  JSON1 _SETCONFIG JSON2

#define JSON_END  JSON4 JSON5
#define JSON_END_TRUNCATED  JSON4_TRUNCATED JSON5
#define JSON_BETWEEN_JOIN ","

#define MSG_INVGPU 1
#define MSG_ALRENA 2
#define MSG_ALRDIS 3
#define MSG_GPUMRE 4
#define MSG_GPUREN 5
#define MSG_GPUNON 6
#define MSG_POOL 7
#define MSG_NOPOOL 8
#define MSG_DEVS 9
#define MSG_NODEVS 10
#define MSG_SUMM 11
#define MSG_GPUDIS 12
#define MSG_GPUREI 13
#define MSG_INVCMD 14
#define MSG_MISID 15
#define MSG_GPUDEV 17

#define MSG_NUMGPU 20

#define MSG_VERSION 22
#define MSG_INVJSON 23
#define MSG_MISCMD 24
#define MSG_MISPID 25
#define MSG_INVPID 26
#define MSG_SWITCHP 27
#define MSG_MISVAL 28
#define MSG_NOADL 29
#define MSG_NOGPUADL 30
#define MSG_INVINT 31
#define MSG_GPUINT 32
#define MSG_MINECONFIG 33
#define MSG_GPUMERR 34
#define MSG_GPUMEM 35
#define MSG_GPUEERR 36
#define MSG_GPUENG 37
#define MSG_GPUVERR 38
#define MSG_GPUVDDC 39
#define MSG_GPUFERR 40
#define MSG_GPUFAN 41
#define MSG_MISFN 42
#define MSG_BADFN 43
#define MSG_SAVED 44
#define MSG_ACCDENY 45
#define MSG_ACCOK 46
#define MSG_ENAPOOL 47
#define MSG_DISPOOL 48
#define MSG_ALRENAP 49
#define MSG_ALRDISP 50
#define MSG_MISPDP 52
#define MSG_INVPDP 53
#define MSG_TOOMANYP 54
#define MSG_ADDPOOL 55

#define MSG_NOTIFY 60

#define MSG_REMLASTP 66
#define MSG_ACTPOOL 67
#define MSG_REMPOOL 68
#define MSG_DEVDETAILS 69
#define MSG_MINESTATS 70
#define MSG_MISCHK 71
#define MSG_CHECK 72
#define MSG_POOLPRIO 73
#define MSG_DUPPID 74
#define MSG_MISBOOL 75
#define MSG_INVBOOL 76
#define MSG_FOO 77
#define MSG_MINECOIN 78
#define MSG_DEBUGSET 79
#define MSG_SETCONFIG 82
#define MSG_UNKCON 83
#define MSG_INVNUM 84
#define MSG_CONPAR 85
#define MSG_CONVAL 86

#define MSG_NOUSTA 88

#define MSG_ZERMIS 94
#define MSG_ZERINV 95
#define MSG_ZERSUM 96
#define MSG_ZERNOSUM 97

#define MSG_BYE 0x101

#define MSG_INVNEG 121
#define MSG_SETQUOTA 122
#define MSG_LOCKOK 123
#define MSG_LOCKDIS 124

#define MSG_CHSTRAT 125
#define MSG_MISSTRAT 126
#define MSG_INVSTRAT 127
#define MSG_MISSTRATINT 128

enum code_severity {
  SEVERITY_ERR,
  SEVERITY_WARN,
  SEVERITY_INFO,
  SEVERITY_SUCC,
  SEVERITY_FAIL
};

enum code_parameters {
  PARAM_GPU,
  PARAM_PID,
  PARAM_GPUMAX,
  PARAM_PMAX,
  PARAM_POOLMAX,

// Single generic case: have the code resolve it - see below
  PARAM_DMAX,

  PARAM_CMD,
  PARAM_POOL,
  PARAM_STR,
  PARAM_BOTH,
  PARAM_BOOL,
  PARAM_SET,
  PARAM_INT,
  PARAM_NONE
};

struct CODES {
  const enum code_severity severity;
  const int code;
  const enum code_parameters params;
  const char *description;
} codes[] = {
 { SEVERITY_ERR,   MSG_INVGPU,  PARAM_GPUMAX, "Invalid GPU id %d - range is 0 - %d" },
 { SEVERITY_INFO,  MSG_ALRENA,  PARAM_GPU,  "GPU %d already enabled" },
 { SEVERITY_INFO,  MSG_ALRDIS,  PARAM_GPU,  "GPU %d already disabled" },
 { SEVERITY_WARN,  MSG_GPUMRE,  PARAM_GPU,  "GPU %d must be restarted first" },
 { SEVERITY_INFO,  MSG_GPUREN,  PARAM_GPU,  "GPU %d sent enable message" },
 { SEVERITY_ERR,   MSG_GPUNON,  PARAM_NONE, "No GPUs" },
 { SEVERITY_SUCC,  MSG_POOL,  PARAM_PMAX, "%d Pool(s)" },
 { SEVERITY_ERR,   MSG_NOPOOL,  PARAM_NONE, "No pools" },

 { SEVERITY_SUCC,  MSG_DEVS,  PARAM_DMAX,   "%d GPU(s)" },
 { SEVERITY_ERR,   MSG_NODEVS,  PARAM_NONE, "No GPUs"
 },

 { SEVERITY_SUCC,  MSG_SUMM,  PARAM_NONE, "Summary" },
 { SEVERITY_INFO,  MSG_GPUDIS,  PARAM_GPU,  "GPU %d set disable flag" },
 { SEVERITY_INFO,  MSG_GPUREI,  PARAM_GPU,  "GPU %d restart attempted" },
 { SEVERITY_ERR,   MSG_INVCMD,  PARAM_NONE, "Invalid command" },
 { SEVERITY_ERR,   MSG_MISID, PARAM_NONE, "Missing device id parameter" },
 { SEVERITY_SUCC,  MSG_GPUDEV,  PARAM_GPU,  "GPU%d" },
 { SEVERITY_SUCC,  MSG_NUMGPU,  PARAM_NONE, "GPU count" },
 { SEVERITY_SUCC,  MSG_VERSION, PARAM_NONE, "SGMiner versions" },
 { SEVERITY_ERR,   MSG_INVJSON, PARAM_NONE, "Invalid JSON" },
 { SEVERITY_ERR,   MSG_MISCMD,  PARAM_CMD,  "Missing JSON '%s'" },
 { SEVERITY_ERR,   MSG_MISPID,  PARAM_NONE, "Missing pool id parameter" },
 { SEVERITY_ERR,   MSG_INVPID,  PARAM_POOLMAX,  "Invalid pool id %d - range is 0 - %d" },
 { SEVERITY_SUCC,  MSG_SWITCHP, PARAM_POOL, "Switching to pool %d:'%s'" },
 { SEVERITY_ERR,   MSG_MISVAL,  PARAM_NONE, "Missing comma after GPU number" },
 { SEVERITY_ERR,   MSG_NOADL, PARAM_NONE, "ADL is not available" },
 { SEVERITY_ERR,   MSG_NOGPUADL,PARAM_GPU,  "GPU %d does not have ADL" },
 { SEVERITY_ERR,   MSG_INVINT,  PARAM_STR,  "Invalid intensity (%s) - must be '" _DYNAMIC  "' or range " MIN_INTENSITY_STR " - " MAX_INTENSITY_STR },
 { SEVERITY_INFO,  MSG_GPUINT,  PARAM_BOTH, "GPU %d set new intensity to %s" },
 { SEVERITY_SUCC,  MSG_MINECONFIG,PARAM_NONE, "sgminer config" },
 { SEVERITY_ERR,   MSG_GPUMERR, PARAM_BOTH, "Setting GPU %d memoryclock to (%s) reported failure" },
 { SEVERITY_SUCC,  MSG_GPUMEM,  PARAM_BOTH, "Setting GPU %d memoryclock to (%s) reported success" },
 { SEVERITY_ERR,   MSG_GPUEERR, PARAM_BOTH, "Setting GPU %d clock to (%s) reported failure" },
 { SEVERITY_SUCC,  MSG_GPUENG,  PARAM_BOTH, "Setting GPU %d clock to (%s) reported success" },
 { SEVERITY_ERR,   MSG_GPUVERR, PARAM_BOTH, "Setting GPU %d vddc to (%s) reported failure" },
 { SEVERITY_SUCC,  MSG_GPUVDDC, PARAM_BOTH, "Setting GPU %d vddc to (%s) reported success" },
 { SEVERITY_ERR,   MSG_GPUFERR, PARAM_BOTH, "Setting GPU %d fan to (%s) reported failure" },
 { SEVERITY_SUCC,  MSG_GPUFAN,  PARAM_BOTH, "Setting GPU %d fan to (%s) reported success" },
 { SEVERITY_ERR,   MSG_MISFN, PARAM_NONE, "Missing save filename parameter" },
 { SEVERITY_ERR,   MSG_BADFN, PARAM_STR,  "Can't open or create save file '%s'" },
 { SEVERITY_SUCC,  MSG_SAVED, PARAM_STR,  "Configuration saved to file '%s'" },
 { SEVERITY_ERR,   MSG_ACCDENY, PARAM_STR,  "Access denied to '%s' command" },
 { SEVERITY_SUCC,  MSG_ACCOK, PARAM_NONE, "Privileged access OK" },
 { SEVERITY_SUCC,  MSG_ENAPOOL, PARAM_POOL, "Enabling pool %d:'%s'" },
 { SEVERITY_SUCC,  MSG_POOLPRIO,PARAM_NONE, "Changed pool priorities" },
 { SEVERITY_ERR,   MSG_DUPPID,  PARAM_PID,  "Duplicate pool specified %d" },
 { SEVERITY_SUCC,  MSG_DISPOOL, PARAM_POOL, "Disabling pool %d:'%s'" },
 { SEVERITY_INFO,  MSG_ALRENAP, PARAM_POOL, "Pool %d:'%s' already enabled" },
 { SEVERITY_INFO,  MSG_ALRDISP, PARAM_POOL, "Pool %d:'%s' already disabled" },
 { SEVERITY_ERR,   MSG_MISPDP,  PARAM_NONE, "Missing addpool details" },
 { SEVERITY_ERR,   MSG_INVPDP,  PARAM_STR,  "Invalid addpool details '%s'" },
 { SEVERITY_ERR,   MSG_TOOMANYP,PARAM_NONE, "Reached maximum number of pools (%d)" },
 { SEVERITY_SUCC,  MSG_ADDPOOL, PARAM_STR,  "Added pool '%s'" },
 { SEVERITY_ERR,   MSG_REMLASTP,PARAM_POOL, "Cannot remove last pool %d:'%s'" },
 { SEVERITY_ERR,   MSG_ACTPOOL, PARAM_POOL, "Cannot remove active pool %d:'%s'" },
 { SEVERITY_SUCC,  MSG_REMPOOL, PARAM_BOTH, "Removed pool %d:'%s'" },
 { SEVERITY_SUCC,  MSG_NOTIFY,  PARAM_NONE, "Notify" },
 { SEVERITY_SUCC,  MSG_DEVDETAILS,PARAM_NONE, "Device Details" },
 { SEVERITY_SUCC,  MSG_MINESTATS,PARAM_NONE,  "sgminer stats" },
 { SEVERITY_ERR,   MSG_MISCHK,  PARAM_NONE, "Missing check cmd" },
 { SEVERITY_SUCC,  MSG_CHECK, PARAM_NONE, "Check command" },
 { SEVERITY_ERR,   MSG_MISBOOL, PARAM_NONE, "Missing parameter: true/false" },
 { SEVERITY_ERR,   MSG_INVBOOL, PARAM_NONE, "Invalid parameter should be true or false" },
 { SEVERITY_SUCC,  MSG_FOO, PARAM_BOOL, "Failover-Only set to %s" },
 { SEVERITY_SUCC,  MSG_MINECOIN,PARAM_NONE, "sgminer coin" },
 { SEVERITY_SUCC,  MSG_DEBUGSET,PARAM_NONE, "Debug settings" },
 { SEVERITY_SUCC,  MSG_SETCONFIG,PARAM_SET, "Set config '%s' to %d" },
 { SEVERITY_ERR,   MSG_UNKCON,  PARAM_STR,  "Unknown config '%s'" },
 { SEVERITY_ERR,   MSG_INVNUM,  PARAM_BOTH, "Invalid number (%d) for '%s' range is 0-9999" },
 { SEVERITY_ERR,   MSG_INVNEG,  PARAM_BOTH, "Invalid negative number (%d) for '%s'" },
 { SEVERITY_SUCC,  MSG_SETQUOTA,PARAM_SET,  "Set pool '%s' to quota %d'" },
 { SEVERITY_ERR,   MSG_CONPAR,  PARAM_NONE, "Missing config parameters 'name,N'" },
 { SEVERITY_ERR,   MSG_CONVAL,  PARAM_STR,  "Missing config value N for '%s,N'" },
 { SEVERITY_INFO,  MSG_NOUSTA,  PARAM_NONE, "No USB Statistics" },
 { SEVERITY_ERR,   MSG_ZERMIS,  PARAM_NONE, "Missing zero parameters" },
 { SEVERITY_ERR,   MSG_ZERINV,  PARAM_STR,  "Invalid zero parameter '%s'" },
 { SEVERITY_SUCC,  MSG_ZERSUM,  PARAM_STR,  "Zeroed %s stats with summary" },
 { SEVERITY_SUCC,  MSG_ZERNOSUM, PARAM_STR, "Zeroed %s stats without summary" },
 { SEVERITY_SUCC,  MSG_LOCKOK,  PARAM_NONE, "Lock stats created" },
 { SEVERITY_WARN,  MSG_LOCKDIS, PARAM_NONE, "Lock stats not enabled" },
 { SEVERITY_SUCC,  MSG_CHSTRAT,  PARAM_STR, "Multipool strategy changed to '%s'" },
 { SEVERITY_ERR,   MSG_MISSTRAT, PARAM_NONE, "Missing multipool strategy" },
 { SEVERITY_ERR,   MSG_INVSTRAT, PARAM_NONE, "Invalid multipool strategy %d" },
 { SEVERITY_ERR,   MSG_MISSTRATINT, PARAM_NONE, "Missing rotate interval" },
 { SEVERITY_SUCC,  MSG_BYE,   PARAM_STR,  "%s" },
 { SEVERITY_FAIL, 0, (enum code_parameters)0, NULL }
};

struct IP4ACCESS {
  in_addr_t ip;
  in_addr_t mask;
  char group;
};

#define GROUP(g) (toupper(g))
#define PRIVGROUP GROUP('W')
#define NOPRIVGROUP GROUP('R')
#define ISPRIVGROUP(g) (GROUP(g) == PRIVGROUP)
#define GROUPOFFSET(g) (GROUP(g) - GROUP('A'))
#define VALIDGROUP(g) (GROUP(g) >= GROUP('A') && GROUP(g) <= GROUP('Z'))
#define COMMANDS(g) (apigroups[GROUPOFFSET(g)].commands)
#define DEFINEDGROUP(g) (ISPRIVGROUP(g) || COMMANDS(g) != NULL)

struct APIGROUPS {
  // This becomes a string like: "|cmd1|cmd2|cmd3|" so it's quick to search
  char *commands;
} apigroups['Z' - 'A' + 1]; // only A=0 to Z=25 (R: noprivs, W: allprivs)

struct io_data {
  size_t siz;
  char *ptr;
  char *cur;
  bool sock;
  bool close;
};

struct io_list {
  struct io_data *io_data;
  struct io_list *prev;
  struct io_list *next;
};

extern void message(struct io_data *io_data, int messageid, int paramid, char *param2, bool isjson);

#define SOCKBUFALLOCSIZ 65536

#define io_new(init) _io_new(init, false)
#define sock_io_new() _io_new(SOCKBUFALLOCSIZ, true)

#if LOCK_TRACKING

  #define LOCK_FMT_FFL " - called from %s %s():%d"
  #define LOCKMSG(fmt, ...) fprintf(stderr, "APILOCK: " fmt "\n", ##__VA_ARGS__)
  #define LOCKMSGMORE(fmt, ...) fprintf(stderr, "          " fmt "\n", ##__VA_ARGS__)
  #define LOCKMSGFFL(fmt, ...) fprintf(stderr, "APILOCK: " fmt LOCK_FMT_FFL "\n", ##__VA_ARGS__, file, func, linenum)
  #define LOCKMSGFLUSH() fflush(stderr)

  typedef struct lockstat {
    uint64_t lock_id;
    const char *file;
    const char *func;
    int linenum;
    struct timeval tv;
  } LOCKSTAT;

  typedef struct lockline {
    struct lockline *prev;
    struct lockstat *stat;
    struct lockline *next;
  } LOCKLINE;

  typedef struct lockinfo {
    void *lock;
    enum cglock_typ typ;
    const char *file;
    const char *func;
    int linenum;
    uint64_t gets;
    uint64_t gots;
    uint64_t tries;
    uint64_t dids;
    uint64_t didnts; // should be tries - dids
    uint64_t unlocks;
    LOCKSTAT lastgot;
    LOCKLINE *lockgets;
    LOCKLINE *locktries;
  } LOCKINFO;

  typedef struct locklist {
    LOCKINFO *info;
    struct locklist *next;
  } LOCKLIST;
#endif

#endif /* API_H */
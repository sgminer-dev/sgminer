#ifndef API_H
#define API_H

#include "config.h"

#include "miner.h"

// BUFSIZ varies on Windows and Linux
#define TMPBUFSIZ 8192

// Number of requests to queue - normally would be small
#define QUEUE 100

#define COMSTR ","
#define SEPSTR "|"

#define CMDJOIN '+'
#define JOIN_CMD "CMD="
#define BETWEEN_JOIN SEPSTR
#define _DYNAMIC "D"

#define _DEVS   "DEVS"
#define _POOLS    "POOLS"
#define _PROFILES    "PROFILES"
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
#define JSON_PROFILES  JSON1 _POOLS JSON2
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

#define MSG_PROFILE 129
#define MSG_NOPROFILE 130

#define MSG_PROFILEEXIST 131
#define MSG_MISPRD 132
#define MSG_ADDPROFILE 133

#define MSG_MISPRID 134
#define MSG_PRNOEXIST 135
#define MSG_PRISDEFAULT 136
#define MSG_PRINUSE 137
#define MSG_REMPROFILE 138

#define MSG_CHPOOLPR 139

#define MSG_INVXINT 140
#define MSG_GPUXINT 141
#define MSG_INVRAWINT 142
#define MSG_GPURAWINT 143

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
  PARAM_PRMAX,
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
};

extern struct CODES codes[];

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
extern bool io_add(struct io_data *io_data, char *buf);
extern void io_close(struct io_data *io_data);
extern void io_free();

extern struct api_data *api_add_escape(struct api_data *root, char *name, char *data, bool copy_data);
extern struct api_data *api_add_string(struct api_data *root, char *name, char *data, bool copy_data);
extern struct api_data *api_add_const(struct api_data *root, char *name, const char *data, bool copy_data);
extern struct api_data *api_add_uint8(struct api_data *root, char *name, uint8_t *data, bool copy_data);
extern struct api_data *api_add_uint16(struct api_data *root, char *name, uint16_t *data, bool copy_data);
extern struct api_data *api_add_int(struct api_data *root, char *name, int *data, bool copy_data);
extern struct api_data *api_add_uint(struct api_data *root, char *name, unsigned int *data, bool copy_data);
extern struct api_data *api_add_uint32(struct api_data *root, char *name, uint32_t *data, bool copy_data);
extern struct api_data *api_add_hex32(struct api_data *root, char *name, uint32_t *data, bool copy_data);
extern struct api_data *api_add_uint64(struct api_data *root, char *name, uint64_t *data, bool copy_data);
extern struct api_data *api_add_double(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_elapsed(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_bool(struct api_data *root, char *name, bool *data, bool copy_data);
extern struct api_data *api_add_timeval(struct api_data *root, char *name, struct timeval *data, bool copy_data);
extern struct api_data *api_add_time(struct api_data *root, char *name, time_t *data, bool copy_data);
extern struct api_data *api_add_mhs(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_khs(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_mhtotal(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_temp(struct api_data *root, char *name, float *data, bool copy_data);
extern struct api_data *api_add_utility(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_freq(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_volts(struct api_data *root, char *name, float *data, bool copy_data);
extern struct api_data *api_add_hs(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_diff(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_percent(struct api_data *root, char *name, double *data, bool copy_data);
extern struct api_data *api_add_avg(struct api_data *root, char *name, float *data, bool copy_data);
extern struct api_data *print_data(struct api_data *root, char *buf, bool isjson, bool precom);

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
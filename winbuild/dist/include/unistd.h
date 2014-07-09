#pragma once

// POSIX open,read,write... deprecated as of VC++ 2005.
// Use ISO conformant _open,_read,_write instead.
#define open _open
#define write _write
#define close _close
#define read _read
#define snprintf _snprintf
#define dup _dup
#define dup2 _dup2

#pragma once

/* Values for the second argument to access.
   These may be OR'd together.  */
#define R_OK    4       /* Test for read permission.  */
#define W_OK    2       /* Test for write permission.  */
#define F_OK    0       /* Test for existence.  */

// POSIX open,read,write... deprecated as of VC++ 2005.
// Use ISO conformant _open,_read,_write instead.
#define access _access
#define dup2 _dup2
#define execve _execve
#define ftruncate _chsize
#define unlink _unlink
#define fileno _fileno
#define getcwd _getcwd
#define chdir _chdir
#define isatty _isatty
#define lseek _lseek
#define open _open
#define write _write
#define close _close
#define read _read
#define snprintf _snprintf

#define STDIN_FILENO  0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
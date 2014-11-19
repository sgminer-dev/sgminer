#ifndef EVENTS_H
#define EVENTS_H

typedef struct event {
  unsigned int id;
  const char *event_type;
  const char *runcmd;
  bool reboot;
  unsigned int reboot_delay;
  bool quit;
  const char *quit_msg;
  struct event *prev, *next;
} event_t;

extern char *set_event_type(const char *event_type);
extern char *set_event_runcmd(const char *cmd);
extern char *set_event_reboot(const char *arg);
extern char *set_event_reboot_delay(const char *delay);
extern char *set_event_quit(const char *arg);
extern char *set_event_quit_message(const char *msg);
extern void event_notify(const char *event_type);

#endif /* EVENTS_H */
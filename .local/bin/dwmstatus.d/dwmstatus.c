#include <stdio.h>
#include <time.h>
#include <string.h>
#include <X11/Xlib.h>
#include <signal.h>

static volatile int keepalive = 1;

static struct tm *tm;
static char tfmt[18];

static Display *dpy;
static int scr;
static Window root;

static FILE *fnow, *ffull, *fstatus;

void signalhandler(int);
void settitle(time_t);

void signalhandler(int num) {
  struct timespec ts;
  time_t sec;
  clock_gettime(CLOCK_REALTIME_COARSE, &ts);
  settitle(ts.tv_sec + 3);
}


void settitle(time_t sec) {
  int now, full;
  double pct;
  char status[32];
  char title[64];

  fseek(fnow, 0, SEEK_SET);
  fscanf(fnow, "%d", &now);

  fseek(ffull, 0, SEEK_SET);
  fscanf(ffull, "%d", &full);

  fseek(fstatus, 0, SEEK_SET);
  fgets(status, 64, fstatus);
  *strchr(status, '\n') = 0;

  pct = 100.0 * now / full;
  tm = localtime(&sec);
  strftime(tfmt, 18, "%a %b %d  %H:%M", tm);
  snprintf(title, 64, "%.2f%% (%s)  %s", pct, status, tfmt);
  XStoreName(dpy, root, title);
  XFlush(dpy);
}

int main(void) {
  struct timespec ts;
  struct timespec tn;

  int ps, pns;
  int rs;

  unsigned long int s, sf;
  unsigned long int rns;

  char tfmt[18];

  time_t sec;

  signal(SIGUSR1, signalhandler);

  fnow = fopen("/sys/class/power_supply/BAT0/energy_now", "r");
  setvbuf(fnow, NULL, _IONBF, 0);

  ffull = fopen("/sys/class/power_supply/BAT0/energy_full", "r");
  setvbuf(ffull, NULL, _IONBF, 0);

  fstatus = fopen("/sys/class/power_supply/BAT0/status", "r");
  setvbuf(fstatus, NULL, _IONBF, 0);

  dpy = XOpenDisplay(NULL);
  if (!dpy) return 1;
  scr = DefaultScreen(dpy);
  root = RootWindow(dpy, scr);

  if (clock_gettime(CLOCK_REALTIME_COARSE, &ts)) return 2;
  sf = ts.tv_sec + 4UL;
  s = ts.tv_sec % 60;
  rns = (s > 56 ? 120U - s : 60U - s) * 1000000000U - (unsigned)ts.tv_nsec;
  sec = ts.tv_sec;
  settitle(sec);
  tn.tv_sec = rns / 1000000000UL;
  tn.tv_nsec = rns % 1000000000UL;
  nanosleep(&tn, NULL);
  while (keepalive) {
    if (clock_gettime(CLOCK_REALTIME_COARSE, &ts)) return 2;
    s = ts.tv_sec % 60;
    rns = (s > 56 ? 120U - s : 60U - s) * 1000000000U - (unsigned)ts.tv_nsec;
    sec = ts.tv_sec + 3;
    settitle(sec);
    tn.tv_sec = rns / 1000000000UL;
    tn.tv_nsec = rns % 1000000000UL;
    nanosleep(&tn, NULL);
  }
  return 0;
}

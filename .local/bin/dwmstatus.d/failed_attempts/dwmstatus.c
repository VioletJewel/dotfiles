#include <X11/Xlib.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <signal.h>

#define TITLE_MAX 255

static char title[TITLE_MAX];

static struct tm *tm;

static Display *dpy;
static int scr;
static Window root;

static volatile int keepalive = 1;

void signalhandler(int _) {
  keepalive = 0;
}

void set_title(const time_t secs) {
  tm = localtime(&secs);
  snprintf(title, TITLE_MAX, "%02d:%02d", tm->tm_hour, tm->tm_min);
  XStoreName(dpy, root, title);
  XFlush(dpy);
}

int main(void) {
  long int avglag, avgdrift, curlag, loopcount, nswait, s;
  struct timespec ts;
  char *dpyname;
  FILE *nowF, *fullF, *statusF;

  signal(SIGINT, signalhandler);

  dpyname = NULL;
  dpy = XOpenDisplay(dpyname);
  if (!dpy) return 1;
  scr = DefaultScreen(dpy);
  root = RootWindow(dpy, scr);

  if (clock_gettime(CLOCK_REALTIME, &ts)) return 2;
  set_title(ts.tv_sec);
  avglag = 0L;
  avgdrift = 4500000L;
  s = ts.tv_sec % 60L;
  curlag = s * 1000000000L + ts.tv_nsec - (s > 57L) * 60000000000L;
  nswait = 60000000000L - curlag - avgdrift;
  printf("%02ld : %02ld : %02ld . %09ld\n",
      (ts.tv_sec % 86400L) / 3600L,
      (ts.tv_sec % 3600L) / 60L,
      ts.tv_sec % 60L,
      ts.tv_nsec);
  ts.tv_sec = nswait / 1000000000L;
  ts.tv_nsec = nswait % 1000000000L;
  printf("sleeping for %ld.%09ld seconds\n\n", ts.tv_sec, ts.tv_nsec);
  nanosleep(&ts, NULL);
  for (loopcount = 0L; ; loopcount++) {
    long int curlag;
    if (clock_gettime(CLOCK_REALTIME, &ts)) return 2;
    set_title(ts.tv_sec);
    s = ts.tv_sec % 60L;
    curlag = s * 1000000000L + ts.tv_nsec - (s > 57L) * 60000000000L;
    avglag = (avglag * (loopcount + 1L) + curlag) / (loopcount + 2L);
    avgdrift += avglag;
    nswait = 60000000000L - avgdrift;
    printf("[%02ld:%02ld:%02ld.%09ld] (avglag: %c%ld.%09ld, avgdrift: %ld.%09ld, curlag: %c%ld.%09ld, sleep: %ld.%09ld)\n",
        (ts.tv_sec % 86400L) / 3600L,
        (ts.tv_sec % 3600L) / 60L,
        ts.tv_sec % 60L,
        ts.tv_nsec,
        avglag < 0 ? '-' : '+',
        labs(avglag) / 1000000000L,
        labs(avglag) % 1000000000L,
        avgdrift / 1000000000L,
        avgdrift % 1000000000L,
        curlag < 0 ? '-' : '+',
        labs(curlag) / 1000000000L,
        labs(curlag) % 1000000000L,
        nswait / 1000000000L,
        nswait % 1000000000L);
    ts.tv_sec = nswait / 1000000000L;
    ts.tv_nsec = nswait % 1000000000L;
    printf("sleeping for %ld.%09ld seconds\n\n", ts.tv_sec, ts.tv_nsec);
    if (nswait < 2000000000L || ts.tv_sec < 2)
      break;
    nanosleep(&ts, NULL);
  }

  // XCloseDisplay(dpy);

}

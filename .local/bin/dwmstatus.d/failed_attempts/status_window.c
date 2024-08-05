#include <stdio.h>
#include <time.h>
#include <math.h>

#define WINSIZE 10

int main(void) {
  struct timespec ts;     // timespec
  unsigned long int s;    // seconds (after the minute mark)
  unsigned long int rns;  // remaining nanoseconds
  unsigned long int lc;   // loopcount
  unsigned int i;         // smaller loopcount
  unsigned long int w[WINSIZE]; // window of sleep times
  unsigned int cw;        // current window

  for (lc=0; lc < WINSIZE; lc++)
    w[lc] = 60000000000UL;
  cw = 0;

  // TODO: instead of using `arns` (like in my second attempt) or
  //       just `rns` (like in my first attempt), maybe use a weighted average
  //       where the `rns` is preferred at first but `arns` is preferred more
  //       and more as `lc` increases.
  //
  //       The problem is that the weight will be fairly arbitrary. Perhaps some
  //       function like sigmoid (activation function)
  //
  //       Instead:
  //       use `w`, window of times, to find the average

  if (clock_gettime(CLOCK_REALTIME_COARSE, &ts)) return 2;
  s = ts.tv_sec % 60;
  rns = (s > 56 ? 120UL - s : 60UL - s) * 1000000000UL - (unsigned)ts.tv_nsec;
  rns = (60U - s) * 1000000000U - (unsigned)ts.tv_nsec;
  printf("%02lu : %02lu : %02lu . %09lu\n",
      ((unsigned long)ts.tv_sec % 86400UL) / 3600UL,
      ((unsigned long)ts.tv_sec % 3600UL) / 60UL,
      ts.tv_sec % 60UL,
      ts.tv_nsec);
  ts.tv_sec = rns / 1000000000UL;
  ts.tv_nsec = rns % 1000000000UL;
  printf("sleeping for %02lu.%09lu\n", ts.tv_sec, ts.tv_nsec);
  nanosleep(&ts, NULL);

  // TODO: clock_gettime() here and set all `w` to rns, then  move
  //       clock_gettime() in loop to bottom of loop (if current approach
  //       unsuccessful)
  
  for (lc=0; ; lc++) {
    unsigned long int arns; // average remaining nanoseconds
    float rc, ra; // ratio for current/average rns

    if (clock_gettime(CLOCK_REALTIME_COARSE, &ts)) return 2;
    s = ts.tv_sec % 60;
    rns = (s > 56 ? 120UL - s : 60UL - s) * 1000000000UL - (unsigned)ts.tv_nsec;
    // arns = (arns * (lc + 1UL) + rns) / (lc + 2UL);
    printf("%02lu : %02lu : %02lu . %09lu\n",
        ((unsigned long)ts.tv_sec % 86400UL) / 3600UL,
        ((unsigned long)ts.tv_sec % 3600UL) / 60UL,
        ts.tv_sec % 60UL,
        ts.tv_nsec);

    arns = 0;
    for (i = 0; i < WINSIZE; i++)
      arns += w[i];
    arns /= WINSIZE;
    w[cw] = rns;
    cw = (cw + 1) % WINSIZE;

    printf("    rem ns: %02lu.%09lu\n", rns / 1000000000UL, rns % 1000000000UL);
    printf("avg rem ns: %02lu.%09lu\n", arns / 1000000000UL, arns % 1000000000UL);

    ra = 1 / (1 + expf(WINSIZE - lc));
    rc = 1 - ra;
    rns = ra * arns + rc * rns;

    ts.tv_sec = rns / 1000000000UL;
    ts.tv_nsec = rns % 1000000000UL;

    printf("sleeping for %02lu.%09lu\n", ts.tv_sec, ts.tv_nsec);
    nanosleep(&ts, NULL);

  }

  return 0;
}

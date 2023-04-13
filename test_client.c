#include <hiredis/hiredis.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char **argv) {
  unsigned int j, isunix = 0;
  redisContext *c;
  redisReply *reply;
  const char *hostname = (argc > 1) ? argv[1] : "127.0.0.1";

  int port = 6379;

  struct timeval timeout = {1, 500000};  // 1.5 seconds
  if (isunix) {
    c = redisConnectUnixWithTimeout(hostname, timeout);
  } else {
    c = redisConnectWithTimeout(hostname, port, timeout);
  }
  if (c == NULL || c->err) {
    if (c) {
      printf("Connection error: %s\n", c->errstr);
      redisFree(c);
    } else {
      printf("Connection error: can't allocate redis context\n");
    }
    exit(1);
  }

  char cmd[100] = "";

  if (argc < 3) {
    printf("Too few args. set/s {k} {v}, or get/g {k}\n");
    exit(1);
  }

  if ((strcmp(argv[2], "s") == 0) || (strcmp(argv[2], "set") == 0)) {
    strcpy(cmd, "SET ");
    strcat(cmd, argv[3]);
    strcat(cmd, " ");
    strcat(cmd, argv[4]);
  } else if ((strcmp(argv[2], "g") == 0) || (strcmp(argv[2], "get") == 0)) {
    strcpy(cmd, "GET ");
    strcat(cmd, argv[3]);
  } else {
    printf("Invalid operation, should choose set/get\n");
    exit(1);
  }

  printf("Sending cmd: %s\n", cmd);

  reply = redisCommand(c, cmd);
  printf("Reply: %s\n", reply->str);
  freeReplyObject(reply);

  /* Disconnects and frees the context */
  redisFree(c);

  return 0;
}

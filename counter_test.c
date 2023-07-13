#include <hiredis/hiredis.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int main(int argc, char **argv) {
  redisContext *c;
  redisReply *reply;
  const char *hostname = "127.0.0.1";

  int port = 6379;
  const char *duration = (argc > 1) ? argv[1] : "1";

  struct timeval timeout = {1, 500000};  // 1.5 seconds
  
  c = redisConnectWithTimeout(hostname, port, timeout);
  
  if (c == NULL || c->err) {
    if (c) {
      printf("Connection error: %s\n", c->errstr);
      redisFree(c);
    } else {
      printf("Connection error: can't allocate redis context\n");
    }
    exit(1);
  }

  printf("Func test\n");
  
  while(1) {
    redisReply *reply = redisCommand(c, "JS %s %s", "counter_test", duration);
    printf("Count for %s ms: %s\n", duration, reply->str);
    freeReplyObject(reply);
  }

  /* Disconnects and frees the context */
  redisFree(c);

  return 0;
}

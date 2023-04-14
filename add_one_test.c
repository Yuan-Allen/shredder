#include <hiredis/hiredis.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

int NUM_THREADS = 8;

struct ReqParam {
  int t_id;
};

void *req_func(void *args) {
  struct timeval timeout = {1, 500000};  // 1.5 seconds
  redisContext *c = redisConnectWithTimeout("127.0.0.1", 6379, timeout);

  if (c == NULL || c->err) {
    if (c) {
      printf("Connection error: %s\n", c->errstr);
      redisFree(c);
    } else {
      printf("Connection error: can't allocate redis context\n");
    }
    exit(1);
  }

  struct ReqParam *params = (struct ReqParam *)args;

  for (int i = 0; i < 1000; ++i) {
    redisReply *reply = redisCommand(c, "JS %s %d", "add_one", 100001);
    printf("JS add_one: thread %d res %s\n", params->t_id, reply->str);
    freeReplyObject(reply);
  }

  return NULL;
}

int main(int argc, char **argv) {
  redisContext *c;
  redisReply *reply;
  const char *hostname = (argc > 1) ? argv[1] : "127.0.0.1";

  int port = 6379;
  const char *depth = (argc > 2) ? argv[2] : "2";

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

  // Run JavaScript function 'setup' to setup test data,
  // including Facebook social graphs and neural network model.
  reply = redisCommand(c, "JS %s", "setup");
  printf("JS setup: %s\n", reply->str);
  freeReplyObject(reply);

  //   reply = redisCommand(c, "JS %s %d", "set_zero", 100001);
  //   printf("JS set_zero: %s\n", reply->str);
  //   freeReplyObject(reply);

  printf("Func test\n");
  pthread_t threads[NUM_THREADS];
  struct ReqParam params[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; ++i) {
    params[i].t_id = i;
    pthread_create(&threads[i], NULL, req_func, &params[i]);
  }

  for (int i = 0; i < NUM_THREADS; ++i) {
    pthread_join(threads[i], NULL);
  }

  /* Disconnects and frees the context */
  redisFree(c);

  return 0;
}

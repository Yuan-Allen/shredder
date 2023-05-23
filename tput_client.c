#include <hiredis/hiredis.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

int NUM_THREADS = 8;

struct ReqParam {
  redisContext *c;
  int t_id;
  const char *depth;
  int count;
};

void* req_func(void *args) {
  struct ReqParam *params = (struct ReqParam *)args;

  srand(params->t_id);

  struct timeval timeout = {1, 500000};  // 1.5 seconds
  params->c = redisConnectWithTimeout("127.0.0.1", 6379, timeout);

  while(1) {
    char start[5];
    int r = rand() % 1000 * 10;
    sprintf(start, "%d", r);

    redisReply *reply = redisCommand(params->c, "JS %s %s %s", "list_traversal", start, params->depth);
    // printf("JS list traversal: start %s, depth %s, res %s\n", start, params->depth, reply->str);
    freeReplyObject(reply);

    (params->count)++;
  }

  return NULL;
}

int main(int argc, char **argv) {
  redisContext *c;
  redisReply *reply;
  const char *hostname = (argc > 1) ? argv[1] : "127.0.0.1";

  int port = 6379;
  const char *depth = (argc > 2) ? argv[2] : "2";

  int do_setup = (argc > 3) ? argc[3] : 1;

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
  if (do_setup) {
    reply = redisCommand(c, "JS %s", "list_traversal_setup");
    printf("JS list_traversal_setup: %s\n", reply->str);
    freeReplyObject(reply);
  }

  printf("Func test\n");
  pthread_t threads[NUM_THREADS];
  struct ReqParam params[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; ++i){
    params[i].c = c;
    params[i].t_id = i;
    params[i].depth = depth;
    params[i].count = 0;
    pthread_create(&threads[i], NULL, req_func, &params[i]);
  }

  while(1) {
    sleep(5);
    int sum = 0;
    for (int i = 0; i < NUM_THREADS; ++i) {
      int cur_count = params[i].count;
      params[i].count = 0;
      printf("Thread %d count %d\n", i, cur_count);
      sum += cur_count;
    }
    printf("Total count %d, tput %d\n", sum, sum / 5);
  }

  /* Disconnects and frees the context */
  redisFree(c);

  return 0;
}

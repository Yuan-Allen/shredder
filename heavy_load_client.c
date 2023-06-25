#include <hiredis/hiredis.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include <unistd.h>

struct ReqParam {
  redisContext *c;
  int t_id;
  int sleep_t_ms;
  int count;
};

void* req_func(void *args) {
  struct ReqParam *params = (struct ReqParam *)args;

  while(1) {
    redisReply *reply = redisCommand(params->c, "JS %s", "load_generator", itoa(params->sleep_t_ms));
    freeReplyObject(reply);

    (params->count)++;
  }

  return NULL;
}

int main(int argc, char **argv) {
  redisContext *c;
  redisReply *reply;
  const char *hostname = "127.0.0.1";

  int port = 6379;
  int sleep_t_ms = (argc > 1) ? atoi(argv[1]) : 100;
  int NUM_THREADS = (argc > 2) ? atoi(argv[2]) : 1;
  
  struct timeval timeout = {1, 500000};  // 1.5 seconds
  
  printf("Func test\n");
  pthread_t threads[NUM_THREADS];
  struct ReqParam params[NUM_THREADS];
  for (int i = 0; i < NUM_THREADS; ++i){
    params[i].c = redisConnectWithTimeout(hostname, port, timeout);
    if (c == NULL || c->err) {
    if (c) {
      printf("Connection error: %s\n", c->errstr);
      redisFree(c);
    } else {
      printf("Connection error: can't allocate redis context\n");
    }
      exit(1);
    }
    params[i].t_id = i;
    params.sleep_t_ms = sleep_t_ms;
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
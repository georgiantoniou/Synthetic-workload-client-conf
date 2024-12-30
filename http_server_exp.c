#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <signal.h>
#include <errno.h>
#include <sched.h>
#include <gsl/gsl_rng.h>
#include <gsl/gsl_randist.h>

#define PORT 8080
#define BUFFER_SIZE 1024
#define RESPONSE "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello World\r\n"

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

int server_socket;

// Requests waiting to be served
int client_queue[BUFFER_SIZE];

//Number of requests in the queue
int queue_size = 0;

// Wait time on the server side in MICROSECONDS
int wait_time;

// Number of threads on the server side
int thread_pool_size;

// Lambda of exponentially distributed service time
double lambda;

// Data of each thread, random number generator plus seed
typedef struct {
    gsl_rng *rng; // GSL RNG for this thread
    unsigned long seed;
} thread_data;


// Function to generate an exponentially distributed random variable
double generate_exponential(gsl_rng *rng, double lambda) {
    return gsl_ran_exponential(rng, 1 / lambda);
}

// Function to sleep for a specified duration in microseconds using nanosleep
void sleep_microseconds(long microseconds) {
    struct timespec req, rem;
    req.tv_sec = microseconds / 1000000;
    req.tv_nsec = (microseconds % 1000000) * 1000;
    while (nanosleep(&req, &rem) == -1 && errno == EINTR) {
        req = rem;
    }
}

// Function to get the current time in microseconds
long long current_time_microseconds() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000LL + tv.tv_usec;
}

//Function to set real time scheduling priority
void set_real_time_priority(pthread_t thread) {
    struct sched_param param;
    param.sched_priority = sched_get_priority_max(SCHED_FIFO);
    if (pthread_setschedparam(thread, SCHED_FIFO, &param) != 0) {
        perror("pthread_setschedparam");
    }
}

void *handle_client(void *arg) {
    pthread_t self = pthread_self();
    set_real_time_priority(self);

    thread_data_t *data = (thread_data_t *)arg;
    gsl_rng *rng = data->rng;

    while (1) {
        int client_socket;

        // Lock and wait for a client connection
        pthread_mutex_lock(&lock);
        while (queue_size == 0) {
            pthread_cond_wait(&cond, &lock);
        }
        client_socket = client_queue[--queue_size];
        pthread_mutex_unlock(&lock);

        // Process the client connection
        char buffer[BUFFER_SIZE];
        ssize_t bytes_read;
        while ((bytes_read = read(client_socket, buffer, sizeof(buffer) - 1)) > 0) {
            buffer[bytes_read] = '\0';  // Null-terminate the read data


            // Simulate service time
            double delay = generate_exponential(rng, lambda);
            sleep_microseconds((int)(delay * 1e6)); // Convert seconds to microseconds
           
            // Send the response
            int bytes_written = write(client_socket, RESPONSE, strlen(RESPONSE));
            if (bytes_written < 0) {
                perror("write failed");
                break;
            } 
        }
        if (bytes_read < 0) {
            perror("read failed");
        }

        close(client_socket);
    }
    gsl_rng_free(rng);
    return NULL;
}

void signal_handler(int sig) {
    close(server_socket);
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <lambda> <num_threads> <seed>\n", argv[0]);
        return EXIT_FAILURE;
    }

    lambda = atof(argv[1]);
    thread_pool_size = atoi(argv[2]);
    unsigned long seed = (unsigned long)atoi(argv[3]);

    struct sockaddr_in server_addr, client_addr;
    socklen_t addr_len = sizeof(client_addr);

    signal(SIGINT, signal_handler);

    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) < 0) {
        perror("bind failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }

    if (listen(server_socket, 100) < 0) {
        perror("listen failed");
        close(server_socket);
        exit(EXIT_FAILURE);
    }
    
    printf("Server listening on port %d\n", PORT);
    printf("Thread pool size: %d\n", thread_pool_size);
    printf("Wait time: %d microseconds\n", wait_time);

    // Create a pool of threads
    pthread_t *thread_pool = malloc(thread_pool_size * sizeof(pthread_t));
    for (int i = 0; i < thread_pool_size; i++) {
        thread_data per_thread_data;
        per_thread_data.rng = gsl_rng_alloc(gsl_rng_default);
        per_thread_data.seed = seed;
        pthread_create(&thread_pool[i], NULL, handle_client, NULL);
    }

    while (1) {
        int client_socket = accept(server_socket, (struct sockaddr *)&client_addr, &addr_len);
        if (client_socket < 0) {
            perror("accept failed");
            continue;
        }

        // Lock and add the client to the queue
        pthread_mutex_lock(&lock);
        client_queue[queue_size++] = client_socket;
        pthread_mutex_unlock(&lock);

        // Signal a thread to handle the client
        pthread_cond_signal(&cond);
    }

    free(thread_pool);
    close(server_socket);
    return 0;
}

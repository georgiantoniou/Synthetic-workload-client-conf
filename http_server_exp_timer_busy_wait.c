#define _GNU_SOURCE
#include <stdio.h>
#include <sched.h> 
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
#define MAX_RECORDS_PER_THREAD 100000  // Adjust as needed

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;
long long current_time_microseconds(void);

int server_socket;

// Flag to indicate when the server should terminate
static int server_running = 1;

// Requests waiting to be served
int client_queue[BUFFER_SIZE];

//Number of requests in the queue
int queue_size = 0;

// Number of threads on the server side
int thread_pool_size;

// Lambda of exponentially distributed service time
double lambda;

// Data of each thread, random number generator plus seed
typedef struct {
    gsl_rng *rng; // GSL RNG for this thread
    unsigned long seed;
    struct timespec start_time;
    int num_records;
    double *execution_times;  // Dynamic array for execution times
    double *theoritical_delays;
    int thread_id;
} thread_data;

// Signal handler to save execution times
void handle_signal(int sig) {
    server_running = 0;  // Notify threads to stop
    close(server_socket);  // Close server socket
    pthread_cond_broadcast(&cond);  // Wake all threads
}

// Start timing a request
void start_timer(thread_data *data) {
    clock_gettime(CLOCK_MONOTONIC, &data->start_time);
}

// Stop timing a request and record the duration
void stop_timer(thread_data *data) {
    struct timespec end_time;
    clock_gettime(CLOCK_MONOTONIC, &end_time);

    double duration = (end_time.tv_sec - data->start_time.tv_sec) +
                      (end_time.tv_nsec - data->start_time.tv_nsec) / 1e9;

    // Save the last MAX_RECORDS_PER_THREAD EACH TIME
    data->execution_times[(data->num_records++)%MAX_RECORDS_PER_THREAD] = duration;
}

// Save execution times to a file
void save_execution_times(int thread_id, thread_data *data) {
    
    char filename[64];
    snprintf(filename, sizeof(filename), "thread_%d_times.log", thread_id);

    FILE *file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    for (int i = 0; i < data->num_records; i++) {
        fprintf(file, "%.10f\n", data->execution_times[i%MAX_RECORDS_PER_THREAD]);
    }

    fclose(file);
    if (data->num_records > MAX_RECORDS_PER_THREAD) {
        perror("Becareful number of records bigger than the response time table size of the thread \n");
    }

    snprintf(filename, sizeof(filename), "thread_%d_delay.log", thread_id);

    file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    for (int i = 0; i < data->num_records; i++) {
        fprintf(file, "%.10f\n", data->theoritical_delays[i%MAX_RECORDS_PER_THREAD]);
    }

    fclose(file);
}

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

// Busy-wait for the specified duration in microseconds
void busy_wait_microseconds(long microseconds) {
    long long start_time = current_time_microseconds();
    while ((current_time_microseconds() - start_time) < microseconds) {
        // Busy-wait loop does nothing, just consumes CPU time
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

// Function to assign a thread to a specific core
void set_thread_affinity(int core_id) {
    cpu_set_t cpuset;
    CPU_ZERO(&cpuset);             // Initialize the CPU set
    CPU_SET(core_id, &cpuset);     // Add the specific core to the set

    pthread_t thread = pthread_self();
    int result = pthread_setaffinity_np(thread, sizeof(cpu_set_t), &cpuset);
    if (result != 0) {
        perror("pthread_setaffinity_np failed");
    } else {
        printf("Thread set to core %d\n", core_id);
    }
}

void *handle_client(void *arg) {
    
    pthread_t self = pthread_self();
    set_real_time_priority(self);

    thread_data *data = (thread_data *)arg;

    // Assign thread to a core (thread_id % number_of_cores)
    int core_id = data->thread_id % sysconf(_SC_NPROCESSORS_ONLN);
    set_thread_affinity(core_id);
     
    // Allocate memory for execution times
    data->execution_times = malloc(sizeof(double) * MAX_RECORDS_PER_THREAD);
    data->theoritical_delays = malloc(sizeof(double) * MAX_RECORDS_PER_THREAD);
    

    if (!data->execution_times) {
        perror("Failed to allocate memory for execution times");
        pthread_exit(NULL);
    }
    data->num_records = 0;

    while (server_running) {
        int client_socket;

        // Lock and wait for a client connection
        pthread_mutex_lock(&lock);
        while (queue_size == 0 && server_running) {
            pthread_cond_wait(&cond, &lock);
        }
        if (!server_running) {
            pthread_mutex_unlock(&lock);
            break;
        }
        client_socket = client_queue[--queue_size];
        pthread_mutex_unlock(&lock);
                
        // Process the client connection
        char buffer[BUFFER_SIZE];
        ssize_t bytes_read;
        while ((bytes_read = read(client_socket, buffer, sizeof(buffer) - 1)) > 0) {
            start_timer(data);
            buffer[bytes_read] = '\0';  // Null-terminate the read data
            
            //get number of requests read
            int request_count = 0;
            const char *search_start = buffer;
            const char *found;

            while ((found = strstr(search_start, "\r\n\r\n")) != NULL) {
                request_count++;
                search_start = found + 4; // Move past the delimiter
                if (search_start >= buffer + bytes_read) {
                    break; // prevent reading out of the buffer.
                }
            }
            
            // Simulate service time
            for (int i=0; i< request_count; i++)
            {   
                if (i != 0)
                    start_timer(data);
                
                double delay = gsl_ran_exponential(data->rng, 1 / lambda);
                busy_wait_microseconds((int)(delay * 1e6)); // Convert seconds to microseconds
                
                data->theoritical_delays[data->num_records%MAX_RECORDS_PER_THREAD] = delay;

                // Send the response
                int bytes_written = write(client_socket, RESPONSE, strlen(RESPONSE));
                if (bytes_written < 0) {
                    perror("write failed");
                    break;
                } 
                stop_timer(data);
            }
        }
        if (bytes_read < 0) {
            perror("read failed");
        }

        close(client_socket);
    }
   
    // Save execution times upon termination
    save_execution_times(data->thread_id, data);
    free(data->execution_times);
    free(data->theoritical_delays);
    gsl_rng_free(data->rng);
    return NULL;
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

    if ((server_socket = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("socket failed");
        exit(EXIT_FAILURE);
    }

    // Setup signal handling for graceful shutdown
    struct sigaction sa;
    sa.sa_handler = handle_signal;
    sa.sa_flags = 0;
    sigaction(SIGINT, &sa, NULL);
    sigaction(SIGTERM, &sa, NULL);

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
    printf("Lambda: %f \n", lambda);
    printf("Seed: %ld \n", seed);
    
    // Initialize GSL RNG
    gsl_rng_env_setup();

    // Create a pool of threads
    pthread_t *thread_pool = malloc(thread_pool_size * sizeof(pthread_t));
    thread_data thread_data_array[thread_pool_size];
    for (int i = 0; i < thread_pool_size; i++) {
        thread_data_array[i].rng = gsl_rng_alloc(gsl_rng_default);
        thread_data_array[i].seed = seed;
        gsl_rng_set(thread_data_array[i].rng, thread_data_array[i].seed); //use same seed for each thread
        thread_data_array[i].thread_id = i;
        pthread_create(&thread_pool[i], NULL, handle_client, &thread_data_array[i]);
    }

    while (server_running) {
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

    for (int i = 0; i < thread_pool_size; i++) {
        pthread_join(thread_pool[i], NULL);
    }

    free(thread_pool);
    close(server_socket);
    return 0;
}

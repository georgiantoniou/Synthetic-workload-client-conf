#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <pthread.h>
#include <signal.h>

#define PORT 8080
#define BUFFER_SIZE 1024
#define RESPONSE "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello World\r\n"
// #define RESPONSE "HTTP/1.1 200 OK\r\nContent-Length: 0\r\n\r\n"
//#define RESPONSE "HTTP/1.1 204 No Content\r\n\r\n"

pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond = PTHREAD_COND_INITIALIZER;

int server_socket;
int client_queue[BUFFER_SIZE];
int queue_size = 0;
// Wait time on the server side in MICROSECONDS
int wait_time;
// Number of threads on the server side
int thread_pool_size;

void *handle_client(void *arg) {
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
        // char buffer[BUFFER_SIZE];
        // read(client_socket, buffer, sizeof(buffer));

        char buffer[BUFFER_SIZE];
        ssize_t bytes_read;
        while ((bytes_read = read(client_socket, buffer, sizeof(buffer) - 1)) > 0) {
        // int bytes_read = read(client_socket, buffer, sizeof(buffer) - 1);
        // if (bytes_read < 0) {
        //     perror("read failed");
        //     close(client_socket);
        //     continue;
        // }
            buffer[bytes_read] = '\0';  // Null-terminate the read data

            // // Log the received request
            // printf("Received request:\n%s\n", buffer);
            
            //printf("Process client connectio\n");
            // Wait for the predefined amount of time
            usleep(wait_time);

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
        // else {
        //     // Log the sent response
        //     printf("Sent response:\n%s\n", RESPONSE);
        // }

        // write(client_socket, RESPONSE, strlen(RESPONSE));

        close(client_socket);
    }
    return NULL;
}

void signal_handler(int sig) {
    close(server_socket);
    exit(0);
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <number_of_threads> <wait_time_microseconds>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    thread_pool_size = atoi(argv[1]);
    wait_time = atoi(argv[2]);

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

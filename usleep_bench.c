#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/time.h>

// Function to get the current time in microseconds
long long current_time_microseconds() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000LL + tv.tv_usec;
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        fprintf(stderr, "Usage: %s <sleep_time_microseconds> <number_of_iterations> <verbose>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    // Parse command-line arguments
    long long sleep_time = atoll(argv[1]);
    int num_iterations = atoi(argv[2]);
    int verbose = atoi(argv[3]);

    if (num_iterations <= 0) {
        fprintf(stderr, "Number of iterations must be greater than 0.\n");
        exit(EXIT_FAILURE);
    }

    long long total_overhead = 0;

    for (int i = 0; i < num_iterations; i++) {
        // Record start time
        long long start_time = current_time_microseconds();

        // Sleep for the specified amount of time
        usleep(sleep_time);

        // Record end time
        long long end_time = current_time_microseconds();

        // Calculate actual sleep time and overhead
        long long actual_sleep_time = end_time - start_time;
        long long overhead = actual_sleep_time - sleep_time;

        // Accumulate total overhead
        total_overhead += overhead;

        // Optionally print detailed results for each iteration
        if (verbose) {
            printf("Iteration %d:\n", i + 1);
            printf("  Requested sleep time: %lld microseconds\n", sleep_time);
            printf("  Actual sleep time: %lld microseconds\n", actual_sleep_time);
            printf("  Overhead: %lld microseconds\n", overhead);
        }
    }

    // Calculate average overhead
    double average_overhead = (double)total_overhead / num_iterations;

    // Print average results
    printf("\nAverage Overhead:\n");
    printf("  Requested sleep time: %lld microseconds\n", sleep_time);
    printf("  Average overhead: %.2f microseconds\n", average_overhead);

    return 0;
}
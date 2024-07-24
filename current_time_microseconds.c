#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

// Function to get the current time in microseconds
long long current_time_microseconds() {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return tv.tv_sec * 1000000LL + tv.tv_usec;
}

int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <number_of_iterations>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    // Number of iterations
    int num_iterations = atoi(argv[1]);
    if (num_iterations <= 0) {
        fprintf(stderr, "Number of iterations must be greater than 0.\n");
        exit(EXIT_FAILURE);
    }

    // Record the start time
    long long start_time = current_time_microseconds();

    // Perform the function calls
    for (int i = 0; i < num_iterations; i++) {
        current_time_microseconds();
    }

    // Record the end time
    long long end_time = current_time_microseconds();

    // Calculate elapsed time and average overhead
    long long total_time = end_time - start_time;
    double average_time_per_call = (double)total_time / num_iterations;

    // Print results
    printf("Number of iterations: %d\n", num_iterations);
    printf("Total time: %lld microseconds\n", total_time);
    printf("Average time per call: %.2f microseconds\n", average_time_per_call);

    return 0;
}

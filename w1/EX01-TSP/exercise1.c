#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>

int main (int argc, char* argv[]) {
    // input: tsp filename, output:
    if(argc != 2) // failsafe to check if user provided input
    {
        printf("Usage: ./exercise1 (filename.tsp)\n");
        exit(0);
    }

    // get the current working directory and build the full path for the filename
    char cwd[PATH_MAX];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {      
        const char *filename = argv[1]; // TODO: add validator for argv[1]
        char fullPath[PATH_MAX];
        snprintf(fullPath, sizeof(fullPath), "%s/%s", cwd, filename);

        printf("Full path: %s\n", fullPath);
    } else {
        perror("getcwd() error");
        return 1;
    }

    // then try to open the file and read it
    FILE* fptr;
    fptr = fopen(fullPath, "r");
    if (NULL == fptr) {
        printf("file can't be opened \n");
          return EXIT_FAILURE;
    }

    // Given a set of cities, return the least-cost Hamiltonian path
    return 0;
}
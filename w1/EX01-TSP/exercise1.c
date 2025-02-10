#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>

typedef struct {
    char* name;
    char* comment;
    char* type; // should be tsp
    int dimension; // no cities
    char* edgeWeightType;
    char* nodeCoordSection;
    double** coordinates; // rest of the lines (coordinates) stored in a 2d array
} tspFile;

int parseTSPFile(const char* filePath, tspFile* tsp) {
    FILE* fptr = fopen(filePath, "r");
    if (fptr == NULL) {
        printf("Error: file can't be opened.\n");
        return -1;
    }

    char line[1024];
    int reading_nodes = 0; // indicate when we are in the NODE_COORD_SECTION
    int nodeIndex = 0;

    while (fgets(line, sizeof(line), fptr) != NULL) {
        line[strcspn(line, "\n")] = '\0'; // remove newline char

        // transfer content to file struct for organization
        if (strncmp(line, "NAME", 4) == 0) {
            tsp->name = strdup(line + 6);
        } else if (strncmp(line, "COMMENT", 7) == 0) {
            tsp->comment = strdup(line + 9);
        } else if (strncmp(line, "TYPE", 4) == 0) {
            tsp->type = strdup(line + 6);
        } else if (strncmp(line, "DIMENSION", 9) == 0) {
            tsp->dimension = atoi(line + 11);
            // allocate memory for node coordinates when dimension is known
            tsp->coordinates = (double**)malloc(tsp->dimension * sizeof(double*));
            for (int i = 0; i < tsp->dimension; i++) {
                tsp->coordinates[i] = (double*)malloc(2 * sizeof(double)); // x and y coordinates
            }
        } else if (strncmp(line, "EDGE_WEIGHT_TYPE", 16) == 0) {
            tsp->edgeWeightType = strdup(line + 18);
        } else if (strncmp(line, "NODE_COORD_SECTION", 18) == 0) {
            reading_nodes = 1;
            tsp->nodeCoordSection = strdup(line);
            continue;  // skip to the next line
        } else if (reading_nodes && nodeIndex < tsp->dimension) {
            int id;
            double x, y;
            if (sscanf(line, "%d %lf %lf", &id, &x, &y) == 3) {
                tsp->coordinates[nodeIndex][0] = x;
                tsp->coordinates[nodeIndex][1] = y;
                nodeIndex++;
            }
        } else if (strncmp(line, "EOF", 3) == 0) {
            break;
        }
    }

    fclose(fptr);
    return 0;
}

int setFullPath(const char filePath, const char* filename) {
    char cwd[1024];
    if (getcwd(cwd, sizeof(cwd)) != NULL) {      
        snprintf(filePath, sizeof(filePath), "%s/%s", cwd, filename);
        printf("Full path: %s\n", filePath);
    } else {
        perror("getcwd() error");
        return -1;
    }
    return 0;
}

int main (int argc, char* argv[]) {
    if(argc != 2) // check if user provided input
    {
        printf("Usage: ./exercise1 (filename.tsp)\n");
        return -1;
    }

    const char *filename = argv[1];
    char *fullPath[1024];
    if (setFullPath(&fullPath, filename) == -1) {
        perror("getcwd() error");
        return -1;
    }

    // init struct to store organized contents of the file
    tspFile tsp = {NULL, NULL, NULL, 0, NULL, NULL};
    // parse content into struct
    if (parseTSPFile(fullPath, &tsp)==-1) {
        perror("error parsing file content");
        return -1;
    }

    // Given a set of cities, return the least-cost Hamiltonian path
    return 0;
}
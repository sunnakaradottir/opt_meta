#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <limits.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>

typedef struct {
    char* name;
    char* comment;
    char* type; // should be tsp
    size_t dimension; // no cities
    char* edgeWeightType;
    char* nodeCoordSection;
    double** coordinates; // rest of the lines (coordinates) stored in a 2d array
} tspFile;


int setFullPath(char* filePath, const char* filename) {
    char* cwd = getcwd(NULL, 0); // dynamic memory allocation
    if (cwd != NULL) {      
        snprintf(filePath, 1024, "%s/%s", cwd, filename);
        free(cwd);
    } else {
        perror("getcwd() error");
        return -1;
    }
    return 0;
}

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

double** distanceMatrix(double** coordinates, size_t dim) {
    double** dist = (double**)malloc(dim * sizeof(double*)); // init 2d array
    if (dist == NULL) {
        fprintf(stderr, "Memory allocation failed\n");
        exit(EXIT_FAILURE);
    }

    for (size_t i = 0; i < dim; i++) { // go through each coordinate
        // allocate memory for each column
        dist[i] = (double*)malloc(dim * sizeof(double));
        if (dist[i] == NULL) {
            fprintf(stderr, "Memory allocation failed\n");
            exit(EXIT_FAILURE);
        }
        for (size_t j = 0; j < dim; j++) { // calculate distance from all other coordinates
            if (i != j) {
                dist[i][j] = round(sqrt(pow(coordinates[j][0] - coordinates[i][0], 2) + pow(coordinates[j][1] - coordinates[i][1], 2)) * 100.0) / 100.0;
            } else {
                dist[i][j] = 0.0;
            }
        }
    }
    return dist;
}

bool hasUnvisited(bool* visitedCities, size_t dim) {
    for (size_t i = 0; i < dim; i++) {
        if (!visitedCities[i]) {
            return true;
        }
    }
    return false;
}

double minimumDistance(double** distanceMatrix, size_t dimension, bool* visitedCities) {
    int currentCity = 0; // start at the first city
    double totalDistance = 0.0;
    visitedCities[currentCity] = true;
    
    // returns the minimum distance of a hamilton cycle, using the NN heuristic
    while (hasUnvisited(visitedCities, dimension)) {
        // mark current city as visited, while there are unvisited cities, find the nearest unvisited cities and then return to origin
        int nearestCity = -1;
        double minDist = INFINITY;
        for (size_t i = 0; i < dimension; i++) {
            if (!visitedCities[i] && distanceMatrix[currentCity][i] < minDist && i!=currentCity) {
                nearestCity = i;
                minDist = distanceMatrix[currentCity][i];
            }
        }
        if (nearestCity != -1) {
            printf("City %d to %d (Distance: %.2f)\n", currentCity+1, nearestCity+1, minDist);
            currentCity = nearestCity;
            totalDistance = totalDistance+minDist;
            visitedCities[nearestCity] = true;
        }
    }
    totalDistance = totalDistance+distanceMatrix[currentCity][0];
    return totalDistance;
}

int main (int argc, char* argv[]) {
    if(argc != 2) // check if user provided input
    {
        printf("Usage: ./exercise1 (filename.tsp)\n");
        return -1;
    }

    const char *filename = argv[1];
    char fullPath[PATH_MAX];
    if (setFullPath(fullPath, filename) == -1) {
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

    // calculate distances between coordinates and store in a 2d array
    double** distances = distanceMatrix(tsp.coordinates, tsp.dimension);
    printf("Distance Matrix:\n\t");
    for (size_t i = 0; i < tsp.dimension; i++) {
        printf("%zu\t", i + 1);
    }
    printf("\n");
    for (size_t i = 0; i < tsp.dimension; i++) {
        printf("%zu\t", i + 1);
        for (size_t j = 0; j < tsp.dimension; j++) {
            printf("%.2f\t", distances[i][j]);
        }
        printf("\n");
    }

    // given a set of cities, return the least-cost Hamiltonian path using NN
    bool visited[tsp.dimension];
    for (size_t i = 0; i < tsp.dimension; i++) {
        visited[i] = false;
    }
    double leastCostPath = minimumDistance(distances, tsp.dimension, visited);

    // free variables
    for (size_t i = 0; i < tsp.dimension; i++) free(distances[i]);
    free(distances);
    printf("Least-Cost Hamiltonian Path: %.2f\n", leastCostPath);
    
    return leastCostPath;
}
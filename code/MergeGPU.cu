#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <cuda.h>


#define NTPB 64
#define NEPT 2
#define SIZE 128
#define MAX(x,y) ((x<=y)? y : x)
#define MIN(x,y) ((x<=y)? x : y)

// Function that catches the error 
void testCUDA(cudaError_t error, const char *file, int line)  {

	if (error != cudaSuccess) {
	   printf("There is an error in file %s at line %d\n", file, line);
       exit(EXIT_FAILURE);
	} 
}
// Has to be defined in the compilation in order to get the correct value of the macros
// __FILE__ and __LINE__
#define testCUDA(error) (testCUDA(error, __FILE__ , __LINE__))

void printGPUCaracteristics(){
	int count;
	cudaDeviceProp prop;

	testCUDA(cudaGetDeviceCount(&count));
	printf("\n\nThe number of devices available is %i GPUs \n", count);
	testCUDA(cudaGetDeviceProperties(&prop, count-1));
	printf("Name: %s\n",  prop.name);
	printf("Global memory size in octet (bytes): %ld\n", prop.totalGlobalMem);
	printf("Shared memory size per block: %ld\n", prop.sharedMemPerBlock);
	printf("Number of registers per block: %i\n", prop.regsPerBlock);
	printf("Number of threads in a warp: %i\n", prop.warpSize);
	printf("Maximum number of threads that can be launched per block: %i\n", 
		   prop.maxThreadsPerBlock);
	printf("Maximum number of threads that can be launched: %i X %i X %i\n", 
		   prop.maxThreadsDim[0], prop.maxThreadsDim[1], prop.maxThreadsDim[2]);
	printf("Maximum grid size: %i X %i X %i\n", prop.maxGridSize[0], 
		   prop.maxGridSize[1], prop.maxGridSize[2]);
	printf("Total constant memory size: %ld\n", prop.totalConstMem);
	printf("Major compute capability: %i\n", prop.major);
	printf("Minor compute capability: %i\n", prop.minor);
	printf("Clock rate: %i\n", prop.clockRate);
	printf("Maximum 1D texture memory: %i\n", prop.maxTexture1D);
	printf("Could we overlap?: %i\n", prop.deviceOverlap);
	printf("Number of multiprocessors: %i\n", prop.multiProcessorCount);
	printf("Is there a limit for kernel execution?: %i\n", 
		   prop.kernelExecTimeoutEnabled);
	printf("Is my GPU a chipset?: %i\n", prop.integrated);
	printf("Can we map the host memory?: %i\n", prop.canMapHostMemory);
	printf("Can we launch concurrent kernels?: %i\n", prop.concurrentKernels);
	printf("Do we have ECC memory?: %i\n", prop.ECCEnabled);
}

/* Cette fonction fait :
* d'abord: chercher le point d'intersection de diagonal avec merge-path 
* et puis merge.
*
* paramètre:
* @ A, B: 2 tableaux triés
* @ C: tableau output qui contient A et B et qui est trié
* @ size_A, size_B : la taille du tableau A et B
* @ thread_id : indentifiant de thread dans la grille
* @ tid : indentifiant de thread dans son block
* @ numThreads : le nombre de threads dans la grille
*/
__device__ void DiagonalIntersection_Merge(int *A, int size_A ,int * B, int size_B, int *C, int thread_id, int tid, int numThreads)
{
	int diag, diaglength,  a_top, b_top, a_bottom, b_bottom;
	int offset, a_end=0, b_end=0, a_start, b_start;
	int numEls = (size_A + size_B)/numThreads;
	int c_start;
	__shared__ int diagA[NTPB];
	__shared__ int diagB[NTPB];

	/*chaque thread détermine sa propre matrice dont diagonal
	* contient le point d'intersection avec merge-path
	*/	
	diag = (thread_id) * numEls;
	a_top = (diag > size_A) ? size_A : diag;
	b_top = (diag > size_A) ? diag - size_A : 0;
	a_bottom = b_top;
	b_bottom = diaglength = (diag > size_A) ? 2*size_A - diag : diag;	
	/*initialiser tableaux diagA, diagB*/
	if (thread_id==0)
	{
		diaglength = 0.5;	
		a_start = diagA[tid] = a_bottom;
		b_start = diagB[tid] = b_top; 
	}
	else
	{
  		diagA[tid] = a_bottom;
		diagB[tid] = b_top + diaglength - 1; 
	}

	/*recherche dichotomique*/		
	while(diaglength > 0.5)
	{
		offset = (a_top - a_bottom)/2;
		a_start    = a_top - offset ;
		b_start    = b_top + offset ;

		/*des cas spécials où l'intersection est sur le bord de matrice A*B*/
		if (a_start == a_top && b_start == 0 | a_start == a_top && b_start == b_bottom | b_start == size_A)
		{
			diagB[tid] = b_start;
			diagA[tid] = a_start;
			break;
		}

		/*des cas réguliers où l'intersection est dans la matrice*/	
		if(A[a_start] > B[b_start-1])
		{
			if(A[a_start-1] <= B[b_start])
			{
				/*le point au milieu est celui d'intersection*/
				diagA[tid] = a_start;
				diagB[tid] = b_start;
				break;
			}
			else
			{
				/*on se deplace sur la partie plus petit*/
				/*redéterminer la nouvelle matrice*/
				a_top = a_start - 1;
				b_top = b_start + 1;
			}
		}
		else
		{
			/*on se deplace sur la partie plus grand*/
			/*redeterminer la nouvelle matrice*/
			a_bottom = a_start;
		}
		diaglength /= 2;
	}

	/*dans la suite, chaque va lire un élément de diagA, un élément de diagB.
	* Pour cela, des écritures dans ces tableaux doivent terminer avant la commence de lecturee. 
	*Faut synchoniser des threads.
	*/
	__syncthreads();

	/*chaque thread lit un élément de diagA et un de diagB 
	* pour determiner a_end, b_end
	*/
	if (tid < NTPB -1)
	{
		a_end = diagA[tid+1];
		b_end = diagB[tid+1];
	}
	else
	{
		/*des threads dont tid = NTPB-1 ne peuvent pas communiquer avec sa voisine à droite
		* car elles sont dans différents block. Pour telle thread, a_end, b_end sont determiné différemment
		*/
		if (thread_id < numThreads - 1)
		{
			a_end = a_start + numEls;
			b_end = b_start + numEls;
		}
		else
		{
			a_end = size_A;
			b_end = size_A;
		}
	}

	__syncthreads();

	/*Partie MERGE*/
	
	c_start = thread_id * numEls;
	
	int c_end = c_start + numEls;
    	while (a_start < a_end && b_start < b_end && c_start < c_end) {
        	if (A[a_start] <= B[b_start]) {
			C[c_start] = A[a_start];
			c_start++;
			a_start++;
        	} else {
			C[c_start] = B[b_start];
			c_start++;
			b_start++;
        	}
    	}

    	while(a_start < a_end  && c_start < c_end) {
		C[c_start] = A[a_start];
		c_start++;
		a_start++;
    	}

	while(b_start < b_end  && c_start < c_end) {
		C[c_start] = B[b_start];
		c_start++;
		b_start++;
    	}
	
}

/*la fonction kernel de chaque thread
*
*paramètre:
*@ A,B : tableaux d'entrée
*@ size_A, size_B : taille de A et B
*@ numThreads : nombre de threads dans la grille
*/
__global__ void kernel(int *A, int *B, int *S,int size_A, int size_B, int numThreads){
	int idx = threadIdx.x + blockIdx.x * blockDim.x;
	DiagonalIntersection_Merge(A, size_A , B, size_B, S, idx, threadIdx.x, numThreads);
}

void printArray(int A[], int size){
    	int i;
    	for (i=0; i < size; i++){
        	printf("%d ", A[i]);
	}
    	printf("\n\n");
}


void wrapper(int *A, int *B, int *S, int size_A, int size_B){

	int *A_GPU , *B_GPU,*S_GPU;
	int size_S = size_A + size_B;

	int tailleA = size_A*sizeof(int);
	int tailleB = size_B*sizeof(int);
	int tailleS = size_S*sizeof(int);

	float TimerV;				// GPU timer instructions
	cudaEvent_t start, stop;		// GPU timer instructions
	testCUDA(cudaEventCreate(&start));		// GPU timer instructions
	testCUDA(cudaEventCreate(&stop));		


	
	
	
	testCUDA(cudaMalloc(&A_GPU,tailleA));
        testCUDA(cudaMalloc(&B_GPU,tailleB));
        testCUDA(cudaMalloc(&S_GPU,tailleS));
 
        testCUDA(cudaMemcpy(A_GPU,A, tailleA,cudaMemcpyHostToDevice));
        testCUDA(cudaMemcpy(B_GPU,B, tailleB,cudaMemcpyHostToDevice));

	/*On veut que chaque thread ait NEPT éléments de C*/
 	int NB = (size_S + (NTPB*NEPT) -1)/(NTPB*NEPT);	
	int numThreads = NB*NTPB;
        testCUDA(cudaEventRecord(start,0));

	kernel<<<NB,NTPB>>>(A_GPU, B_GPU, S_GPU, size_A, size_B, numThreads);
	printf ("NB = %d, NTPB = %d, numthreads = %d\n", NB, NTPB, numThreads);
	
	testCUDA(cudaEventRecord(stop,0));
	testCUDA(cudaEventSynchronize(stop));
	testCUDA(cudaEventElapsedTime(&TimerV,start, stop));

	testCUDA(cudaMemcpy(S,S_GPU, tailleS,cudaMemcpyDeviceToHost));
	
	cudaDeviceSynchronize();
	

	printf("\nExecution time: %f ms\n", TimerV);
        testCUDA(cudaFree(A_GPU));
	testCUDA(cudaFree(B_GPU));
        testCUDA(cudaFree(S_GPU));
}

int main(int argc, char const *argv[]){
	

	FILE * f;
	int *A , *B, *S;
	int A_size, B_size, S_size;
	int i;
	/*================= Recupétation des deux tableaux dans un fichier =================*/

	if (argc < 2) {
        	fprintf( stderr,"Usage: <%s> <JeuxDeDonnees/fichier>\n", argv[0]);
        	return 1;
    	}

	if( (f=fopen(argv[1], "r"))==NULL) {
        	fprintf(stderr,"erreur a la lecture du fichier %s\n", argv[1]);
        	exit(1);
    	}
	
	char ch_a[10] = {0};
    	char ch_b[10] = {0};

	fscanf(f, "%s %s", ch_a,ch_b);
    	A_size = atoi(ch_a);
    	B_size = atoi(ch_b);
	S_size =  A_size + B_size;
	printf("\nSize of A: %d\n",A_size);
	printf("Size of B: %d\n\n",B_size);

	if (SIZE != A_size | NTPB != A_size/NEPT)
	{
		printf ("Make sure : SIZE = %d, NTPB = %d\n", A_size, A_size/NEPT);
		printf ("Please retry !\n");
		return 0;
	}
	
	

	A = (int*) malloc((A_size)*sizeof(int));
	B = (int*) malloc((B_size)*sizeof(int));
	S = (int*) malloc((S_size)*sizeof(int));

	int max = MAX(A_size,B_size);
	int min = MIN(A_size,B_size);

	for(i = 0; i < max; i++){
		if(i < min){
			fscanf(f,"%ld %ld",&A[i],&B[i]);
		}
		else{
			if(min == A_size){
				fscanf(f,"%ld",&B[i]);
			}
			else{
				fscanf(f,"%ld",&A[i]);
			}
		}	
	}
	/*===============================================================================*/


	printGPUCaracteristics();
    	if(A_size == max){
		wrapper(A, B, S, A_size, B_size);
	}
	else{
		wrapper(B, A, S, B_size, A_size);
	}
	
	printf("Given array are \n");
    
	printf("A: ");
	printArray(A, A_size);
	printf("B: ");
	printArray(B, B_size);
    	printf("\nSorted array is \n");
    	printArray(S, S_size);


    
	free(A);
	free(B);
	free(S);


	return 0;
 }

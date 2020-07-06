#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "omp.h"

#define MAX(x,y) ((x<=y)? y : x)
#define MIN(x,y) ((x<=y)? x : y)

#define MAX_SIZE 8






void print_list(int * x, int n) {
   int i;
   for (i = 0; i < n; i++) {
      printf("%d ",x[i]);
   }
   printf("\n");
}


void merge(int * X, int X_size, int * Y, int Y_size, int * tmp) {
   int i = 0;
   int j = 0;
   int ti = 0;
   int ti_end = X_size + Y_size;

   while (i<X_size && j<Y_size) {
      if (X[i] <= Y[j]) {
         tmp[ti] = X[i];
         ti++; i++;
      } else {
         tmp[ti] = Y[j];
         ti++; j++;
      }
   }
   while (i<X_size && ti < ti_end ) { /* finish up lower half */
      tmp[ti] = X[i];
      ti++; i++;
   }
      while (j<Y_size && ti < ti_end) { /* finish up upper half */
         tmp[ti] = Y[j];
         ti++; j++;
   }
   //memcpy(X, tmp, n*sizeof(int));

} // end of merge()

void mergesort(int * X, int X_size, int *Y, int Y_size,int * tmp)
{
   if (X_size + Y_size < 2) return;

    /* merge sorted halves into sorted list */
   merge(X, X_size, Y, Y_size, tmp);
}


int main(int argc, char const *argv[])
{

   	FILE * f;
        int *A , *B, *S;
        int A_size, B_size, S_size;
        int i;
	
	char nom[100];
	char chemin[500];
	FILE *reference;
	
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



   	double start, stop;

   	//printf("List Before Sorting...\n");
   	//print_list(A, A_size);
   	//print_list(B, B_size);
   	start = omp_get_wtime();
   	#pragma omp parallel
   	{
      		#pragma omp single
      		mergesort(A,A_size,B,B_size,S);
   	}
   	stop = omp_get_wtime();
   	//printf("\nList After Sorting...\n");
   	//print_list(S, S_size);
  	printf("\nTime: %g\n",stop-start);

	/*============================= enregister les donnees de reference ==================*/
 	sprintf(nom, "ref_N%ld_alea",S_size);
	sprintf(chemin,"/users/Etu4/3602734/HPCA/HPCA_2017_2018/PROJET/CODE/JeuxDeDonnees/REF/%s",nom);
	reference = fopen(chemin, "w+");

	for(i = 0 ; i < S_size; i++){
		fprintf(reference, "%ld\n",S[i]);
	}
	fclose(reference);
	printf("Resultat ecit dans: %s\n", chemin);


   	free(A);
   	free(B);
   	free(S);

	return EXIT_SUCCESS; 
}


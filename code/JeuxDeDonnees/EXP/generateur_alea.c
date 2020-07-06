#include <stdlib.h>
#include <stdio.h>

#define MY_RAND(I) (long)((I)*drand48())
#define MIN(x,y) ((x<=y)?x:y)
#define MAX(x,y) ((x>=y)?x:y)


typedef struct {
	long x;
	//long x;
} point;

// Comparaison suivant x: 
int compare_point(const void * a, const void * b){
  	point* pa = (point *)a;
  	point* pb = (point *)b;

  	if( pa->x  < pb->x)
  		return -1;
  	if( pa->x  > pb->x)
    		return 1;
  	/* pa->x  == pb->x */
  	return 0;
}



int main(int argc, char **argv){
  	long size_A,size_B,i,j, n,borne;
  	point *tab_A, *tab_B;
	
  	char nom[100];
  	FILE *f;
  
  	if (argc < 4){
    		fprintf(stderr, "Usage: a.out size_A size_B Borne\n");
  	}

  	size_A = atol(argv[1]);
  	size_B = atol(argv[2]);
	borne = atol(argv[3]);
 
  
  	printf("Generation aleatoire pour : Taille de A =%ld, Taille de B =%ld\n",size_A, size_B); 

  	tab_A = (point *) malloc(size_A * sizeof(point)); 
	tab_B = (point *) malloc(size_B * sizeof(point));

  	///// Generation aleatoire : 
  	srand48(42);

  	// les points :
  	for ( i=0; i<size_A; i++){
    		tab_A[i].x = MY_RAND(borne);
  	}

	for ( i=0; i<size_B; i++){
    		tab_B[i].x = MY_RAND(borne); 
  	}
  
  	///// Tri  :
  	qsort(tab_A, size_A, sizeof(point),compare_point);
	qsort(tab_B, size_B, sizeof(point),compare_point);


  	///// Sauvegarde :
	n = size_A + size_B;
  	sprintf(nom, "ex_N%ld_alea", n);
  	f=fopen(nom, "w+"); 
	
  	fprintf(f, "%ld %ld\n", size_A,  size_B);
  	int max = MAX(size_A,size_B);
	int min = MIN(size_A,size_B);
  	for ( i=0; i<max; i++){
		if(i < min ){
    			fprintf(f, "%ld %ld\n", tab_A[i].x,tab_B[i].x);
		}
		else{
			if(max == size_A){
				fprintf(f, "%ld\n", tab_A[i].x);
			}
			else{
				fprintf(f, "   %ld\n", tab_B[i].x);
			}
		}
    		
  	}
	/*
	fprintf(f, "\n");
	for ( i=0; i<size_B; i++){
    		fprintf(f, "%ld ", tab_B[i].x);
    		
  	}
	fprintf(f, "\n");
*/
  	fclose(f); 
  	printf("Resultat ecrit dans : %s\n", nom);   
  
  	free(tab_A); 
	free(tab_B); 

  	return EXIT_SUCCESS; 
}
